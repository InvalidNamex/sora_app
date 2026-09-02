-- Durable admin inbox entries and automatic alerts for customer feedback.

create table if not exists public.admin_notifications (
  id bigserial primary key,
  event_type text not null,
  title text not null,
  body text not null,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists admin_notifications_created_idx
  on public.admin_notifications (created_at desc);

create table if not exists public.admin_notification_reads (
  notification_id bigint not null
    references public.admin_notifications(id) on delete cascade,
  admin_uid text not null,
  read_at timestamptz not null default now(),
  primary key (notification_id, admin_uid)
);

alter table public.admin_notifications enable row level security;
alter table public.admin_notification_reads enable row level security;

drop policy if exists "Admins can view admin notifications"
  on public.admin_notifications;
create policy "Admins can view admin notifications"
on public.admin_notifications for select to authenticated
using (
  exists (
    select 1 from public.users
    where uid = (select auth.jwt() ->> 'sub')
      and "isAdmin" = true
  )
);

drop policy if exists "Admins can view their notification reads"
  on public.admin_notification_reads;
create policy "Admins can view their notification reads"
on public.admin_notification_reads for select to authenticated
using (
  admin_uid = (select auth.jwt() ->> 'sub')
  and exists (
    select 1 from public.users
    where uid = (select auth.jwt() ->> 'sub')
      and "isAdmin" = true
  )
);

drop policy if exists "Admins can mark notifications read"
  on public.admin_notification_reads;
create policy "Admins can mark notifications read"
on public.admin_notification_reads for insert to authenticated
with check (
  admin_uid = (select auth.jwt() ->> 'sub')
  and exists (
    select 1 from public.users
    where uid = (select auth.jwt() ->> 'sub')
      and "isAdmin" = true
  )
);

grant select on public.admin_notifications to authenticated;
grant select, insert on public.admin_notification_reads to authenticated;

create or replace function public.enqueue_admin_feedback_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_event_type text;
  v_title text;
  v_body text;
  v_payload jsonb;
begin
  v_event_type := case
    when new.delivery_rating <= 2 then 'admin_low_rating_received'
    else 'admin_review_submitted'
  end;
  v_title := case
    when new.delivery_rating <= 2 then format('Low rating for order #%s', new.order_id)
    else format('New customer review #%s', new.order_id)
  end;
  v_body := format(
    'A customer submitted a %s/5 delivery rating%s.',
    new.delivery_rating,
    case when new.delivery_comment is null then '' else ' with a comment' end
  );
  v_payload := jsonb_build_object(
    'order_id', new.order_id,
    'rating', new.delivery_rating,
    'target_audience', 'admins',
    'deep_link', '/admin-feedback'
  );

  insert into public.admin_notifications (event_type, title, body, payload)
  values (v_event_type, v_title, v_body, v_payload);

  insert into public.notification_jobs ("eventType", title, body, payload)
  values (v_event_type, v_title, v_body, v_payload);

  return new;
end;
$$;

drop trigger if exists trg_enqueue_admin_feedback_notification
  on public.order_feedback;
create trigger trg_enqueue_admin_feedback_notification
after insert on public.order_feedback
for each row
execute function public.enqueue_admin_feedback_notification();

create or replace function public.enqueue_admin_product_review_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_title text := format('Low product rating for order #%s', new.order_id);
  v_body text := format('A customer gave a product a %s/5 rating.', new.product_rating);
  v_payload jsonb := jsonb_build_object(
    'order_id', new.order_id,
    'review_id', new.id,
    'rating', new.product_rating,
    'target_audience', 'admins',
    'deep_link', '/admin-feedback'
  );
begin
  if new.product_rating > 2 then
    return new;
  end if;

  insert into public.admin_notifications (event_type, title, body, payload)
  values ('admin_low_product_rating_received', v_title, v_body, v_payload);

  insert into public.notification_jobs ("eventType", title, body, payload)
  values ('admin_low_product_rating_received', v_title, v_body, v_payload);

  return new;
end;
$$;

drop trigger if exists trg_enqueue_admin_product_review_notification
  on public.product_reviews;
create trigger trg_enqueue_admin_product_review_notification
after insert on public.product_reviews
for each row
execute function public.enqueue_admin_product_review_notification();

create or replace function public.enqueue_admin_suggestion_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_title text := format('New item suggestion: %s', new.item_name);
  v_body text := 'A customer submitted an item suggestion for review.';
  v_payload jsonb := jsonb_build_object(
    'suggestion_id', new.id,
    'target_audience', 'admins',
    'deep_link', '/admin-item-suggestions'
  );
begin
  insert into public.admin_notifications (event_type, title, body, payload)
  values ('admin_item_suggestion_submitted', v_title, v_body, v_payload);

  insert into public.notification_jobs ("eventType", title, body, payload)
  values ('admin_item_suggestion_submitted', v_title, v_body, v_payload);

  return new;
end;
$$;

drop trigger if exists trg_enqueue_admin_suggestion_notification
  on public.item_suggestions;
create trigger trg_enqueue_admin_suggestion_notification
after insert on public.item_suggestions
for each row
execute function public.enqueue_admin_suggestion_notification();
