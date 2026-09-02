-- Customer item returns with an auditable admin workflow.
alter table public.order_master
  add column if not exists delivered_at timestamptz;

create table if not exists public.return_requests (
  id bigserial primary key,
  order_id bigint not null references public.order_master(id) on delete cascade,
  order_detail_id bigint not null references public.order_detail(id) on delete cascade,
  user_id bigint not null references public.users(id) on delete cascade,
  customer_name text not null,
  customer_phone text not null,
  has_whatsapp boolean not null,
  reason text not null,
  status text not null default 'Requested'
    check (status in ('Requested', 'Under Review', 'Approved', 'Rejected',
                      'Pickup Scheduled', 'Received', 'Completed', 'Cancelled')),
  admin_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (order_detail_id, user_id)
);

create index if not exists return_requests_status_idx
  on public.return_requests (status, created_at desc);
create index if not exists return_requests_user_idx
  on public.return_requests (user_id, created_at desc);

alter table public.return_requests enable row level security;
grant select, insert on public.return_requests to authenticated;
grant update on public.return_requests to authenticated;

drop policy if exists "Customers can view their return requests" on public.return_requests;
create policy "Customers can view their return requests" on public.return_requests
for select to authenticated using (
  user_id = (select id from public.users where uid = (select auth.jwt() ->> 'sub'))
  or exists (select 1 from public.users where uid = (select auth.jwt() ->> 'sub') and "isAdmin" = true)
);

drop policy if exists "Customers can create delivered item returns" on public.return_requests;
create policy "Customers can create delivered item returns" on public.return_requests
for insert to authenticated with check (
  user_id = (select id from public.users where uid = (select auth.jwt() ->> 'sub'))
  and customer_name <> '' and customer_phone <> '' and reason <> ''
  and exists (
    select 1 from public.order_master om
    join public.order_detail od on od."orderMasterID" = om.id
    where om.id = order_id and od.id = order_detail_id
      and om."userID" = user_id and om."orderStatus" = 'Delivered'
  )
);

drop policy if exists "Admins can update return requests" on public.return_requests;
create policy "Admins can update return requests" on public.return_requests
for update to authenticated using (
  exists (select 1 from public.users where uid = (select auth.jwt() ->> 'sub') and "isAdmin" = true)
) with check (
  exists (select 1 from public.users where uid = (select auth.jwt() ->> 'sub') and "isAdmin" = true)
);

create or replace function public.set_order_delivered_at()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new."orderStatus" = 'Delivered' and old."orderStatus" is distinct from 'Delivered'
     and new.delivered_at is null then
    new.delivered_at := now();
  end if;
  return new;
end;
$$;
drop trigger if exists trg_set_order_delivered_at on public.order_master;
create trigger trg_set_order_delivered_at before update of "orderStatus" on public.order_master
for each row execute function public.set_order_delivered_at();

create or replace function public.enqueue_return_request_notifications()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_uid text; v_item text;
begin
  select u.uid into v_uid from public.users u where u.id = new.user_id;
  select coalesce(od."itemName", 'item') into v_item from public.order_detail od where od.id = new.order_detail_id;
  if tg_op = 'INSERT' then
    insert into public.admin_notifications (event_type, title, body, payload)
    values ('admin_return_requested', format('Return request for order #%s', new.order_id),
      format('%s requested a return for %s. Reason: %s', new.customer_name, v_item, new.reason),
      jsonb_build_object('return_request_id', new.id, 'order_id', new.order_id, 'target_audience', 'admins', 'deep_link', '/admin-returns'));
    insert into public.notification_jobs ("eventType", title, body, payload)
    values ('admin_return_requested', format('Return request for order #%s', new.order_id),
      format('%s requested a return for %s.', new.customer_name, v_item),
      jsonb_build_object('return_request_id', new.id, 'order_id', new.order_id, 'target_audience', 'admins', 'deep_link', '/admin-returns'));
  elsif old.status is distinct from new.status then
    insert into public.notification_jobs ("eventType", title, body, payload)
    values ('return_status_changed', format('Return request #%s updated', new.id),
      format('Your return request for %s is now: %s.', v_item, new.status),
      jsonb_build_object('return_request_id', new.id, 'order_id', new.order_id, 'target_user_uid', v_uid, 'deep_link', format('/orders/%s', new.order_id)));
  end if;
  return new;
end;
$$;
create or replace function public.touch_return_request()
returns trigger language plpgsql as $$
begin new.updated_at := now(); return new; end;
$$;
drop trigger if exists trg_touch_return_request on public.return_requests;
create trigger trg_touch_return_request before update on public.return_requests
for each row execute function public.touch_return_request();
drop trigger if exists trg_return_request_notifications on public.return_requests;
create trigger trg_return_request_notifications after insert or update of status on public.return_requests
for each row execute function public.enqueue_return_request_notifications();
