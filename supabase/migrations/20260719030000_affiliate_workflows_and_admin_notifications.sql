-- Affiliate applications, auditable payouts, and targeted admin notifications.

create table if not exists public.affiliate_applications (
  id bigserial primary key,
  "userID" bigint not null references public.users(id) on delete cascade,
  "preferredCode" text not null,
  message text not null,
  status text not null default 'Pending'
    check (status in ('Pending', 'Approved', 'Rejected')),
  "adminNote" text,
  "reviewedBy" bigint references public.users(id) on delete set null,
  "reviewedAt" timestamptz,
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now(),
  constraint affiliate_applications_code_format
    check ("preferredCode" ~ '^[A-Z0-9]{4,20}$'),
  constraint affiliate_applications_message_length
    check (char_length(message) between 10 and 500)
);

create unique index if not exists affiliate_applications_one_pending
  on public.affiliate_applications ("userID")
  where status = 'Pending';

create unique index if not exists affiliate_applications_pending_code_unique
  on public.affiliate_applications (upper("preferredCode"))
  where status = 'Pending';

create index if not exists affiliate_applications_admin_queue
  on public.affiliate_applications (status, "createdAt");

alter table public.payout_requests
  add column if not exists "payoutMethod" text,
  add column if not exists "payoutAccount" text,
  add column if not exists "paymentReference" text,
  add column if not exists "adminNote" text,
  add column if not exists "reviewedBy" bigint references public.users(id)
    on delete set null,
  add column if not exists "reviewedAt" timestamptz;

create or replace function public.submit_affiliate_application(
  p_user_uid text,
  p_preferred_code text,
  p_message text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id bigint;
  v_code text := upper(trim(coalesce(p_preferred_code, '')));
  v_message text := trim(coalesce(p_message, ''));
  v_application_id bigint;
begin
  select id into v_user_id
  from public.users
  where uid = p_user_uid;

  if v_user_id is null then
    raise exception 'User profile not found';
  end if;

  if exists (
    select 1 from public.users
    where id = v_user_id and "isAffiliate" = true
  ) then
    raise exception 'User is already an affiliate';
  end if;

  if v_code !~ '^[A-Z0-9]{4,20}$' then
    raise exception 'Code must contain 4-20 letters or numbers';
  end if;

  if char_length(v_message) < 10 or char_length(v_message) > 500 then
    raise exception 'Application message must contain 10-500 characters';
  end if;

  if exists (
    select 1 from public.affiliate_codes
    where upper(code) = v_code
  ) then
    raise exception 'Code is already in use';
  end if;

  if exists (
    select 1 from public.affiliate_applications
    where "userID" = v_user_id and status = 'Pending'
  ) then
    raise exception 'An affiliate application is already pending';
  end if;

  if exists (
    select 1 from public.affiliate_applications
    where upper("preferredCode") = v_code and status = 'Pending'
  ) then
    raise exception 'Code is already requested by another application';
  end if;

  insert into public.affiliate_applications (
    "userID",
    "preferredCode",
    message
  ) values (
    v_user_id,
    v_code,
    v_message
  )
  returning id into v_application_id;

  insert into public.notification_jobs (
    "eventType",
    title,
    body,
    payload
  ) values (
    'affiliate_application_submitted',
    'New affiliate application',
    format('Affiliate application #%s is ready for review.', v_application_id),
    jsonb_build_object(
      'application_id', v_application_id,
      'target_audience', 'admins',
      'deep_link', '/admin-affiliates'
    )
  );

  return jsonb_build_object(
    'id', v_application_id,
    'preferredCode', v_code,
    'message', v_message,
    'status', 'Pending',
    'createdAt', now()
  );
end;
$$;

create or replace function public.review_affiliate_application(
  p_admin_uid text,
  p_application_id bigint,
  p_decision text,
  p_admin_note text default ''
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_admin_id bigint;
  v_application public.affiliate_applications%rowtype;
  v_user_uid text;
  v_status text;
begin
  select id into v_admin_id
  from public.users
  where uid = p_admin_uid and "isAdmin" = true;

  if v_admin_id is null then
    raise exception 'Forbidden';
  end if;

  select * into v_application
  from public.affiliate_applications
  where id = p_application_id
  for update;

  if v_application.id is null then
    raise exception 'Affiliate application not found';
  end if;

  if v_application.status <> 'Pending' then
    raise exception 'Affiliate application has already been reviewed';
  end if;

  v_status := case lower(trim(p_decision))
    when 'approve' then 'Approved'
    when 'reject' then 'Rejected'
    else null
  end;

  if v_status is null then
    raise exception 'Invalid application decision';
  end if;

  if v_status = 'Approved' then
    update public.users
    set "isAffiliate" = true
    where id = v_application."userID";

    update public.affiliate_codes
    set code = v_application."preferredCode",
        "isActive" = true,
        "updatedAt" = now()
    where "affiliateID" = v_application."userID";
  end if;

  update public.affiliate_applications
  set status = v_status,
      "adminNote" = nullif(trim(coalesce(p_admin_note, '')), ''),
      "reviewedBy" = v_admin_id,
      "reviewedAt" = now(),
      "updatedAt" = now()
  where id = v_application.id;

  select uid into v_user_uid
  from public.users
  where id = v_application."userID";

  insert into public.notification_jobs (
    "eventType",
    title,
    body,
    payload
  ) values (
    'affiliate_application_reviewed',
    'Affiliate application updated',
    case
      when v_status = 'Approved'
        then 'Your affiliate application was approved.'
      else 'Your affiliate application was not approved.'
    end,
    jsonb_build_object(
      'application_id', v_application.id,
      'status', v_status,
      'target_user_uid', v_user_uid,
      'deep_link', case
        when v_status = 'Approved' then '/affiliate'
        else '/home'
      end
    )
  );

  return jsonb_build_object(
    'id', v_application.id,
    'status', v_status
  );
end;
$$;

drop function if exists public.request_affiliate_payout(text);

create or replace function public.request_affiliate_payout(
  p_user_uid text,
  p_payout_method text,
  p_payout_account text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_affiliate_id bigint;
  v_amount numeric(12, 2);
  v_request_id bigint;
  v_method text := lower(trim(coalesce(p_payout_method, '')));
  v_account text := trim(coalesce(p_payout_account, ''));
begin
  select id into v_affiliate_id
  from public.users
  where uid = p_user_uid and "isAffiliate" = true;

  if v_affiliate_id is null then
    raise exception 'Affiliate profile not found';
  end if;

  if v_method not in ('mobile_wallet', 'instapay', 'bank_transfer') then
    raise exception 'Invalid payout method';
  end if;

  if char_length(v_account) < 5 or char_length(v_account) > 100 then
    raise exception 'Enter a valid payout account';
  end if;

  perform 1
  from public.affiliate_commissions
  where "affiliateID" = v_affiliate_id and status = 'available'
  for update;

  select round(coalesce(sum(amount), 0), 2)
  into v_amount
  from public.affiliate_commissions
  where "affiliateID" = v_affiliate_id and status = 'available';

  if v_amount <= 0 then
    raise exception 'No available balance';
  end if;

  insert into public.payout_requests (
    "affiliateID",
    amount,
    status,
    "payoutMethod",
    "payoutAccount"
  ) values (
    v_affiliate_id,
    v_amount,
    'Pending',
    v_method,
    v_account
  )
  returning id into v_request_id;

  update public.affiliate_commissions
  set status = 'processing',
      "payoutRequestID" = v_request_id
  where "affiliateID" = v_affiliate_id and status = 'available';

  insert into public.notification_jobs (
    "eventType",
    title,
    body,
    payload
  ) values (
    'affiliate_payout_requested',
    'New affiliate payout request',
    format('Payout request #%s for EGP %s is ready for review.',
      v_request_id, v_amount),
    jsonb_build_object(
      'payout_request_id', v_request_id,
      'target_audience', 'admins',
      'deep_link', '/admin-affiliates'
    )
  );

  return jsonb_build_object(
    'payout_request_id', v_request_id,
    'amount', v_amount,
    'payout_method', v_method,
    'payout_account', v_account
  );
end;
$$;

create or replace function public.review_affiliate_payout(
  p_admin_uid text,
  p_request_id bigint,
  p_decision text,
  p_payment_reference text default null,
  p_admin_note text default ''
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_admin_id bigint;
  v_request public.payout_requests%rowtype;
  v_user_uid text;
  v_status text;
  v_reference text := trim(coalesce(p_payment_reference, ''));
begin
  select id into v_admin_id
  from public.users
  where uid = p_admin_uid and "isAdmin" = true;

  if v_admin_id is null then
    raise exception 'Forbidden';
  end if;

  select * into v_request
  from public.payout_requests
  where id = p_request_id
  for update;

  if v_request.id is null then
    raise exception 'Payout request not found';
  end if;

  if v_request.status <> 'Pending' then
    raise exception 'Payout request has already been reviewed';
  end if;

  v_status := case lower(trim(p_decision))
    when 'paid' then 'Paid'
    when 'reject' then 'Rejected'
    else null
  end;

  if v_status is null then
    raise exception 'Invalid payout decision';
  end if;

  if v_status = 'Paid' and char_length(v_reference) < 3 then
    raise exception 'Payment reference is required';
  end if;

  update public.payout_requests
  set status = v_status,
      "paymentReference" = case
        when v_status = 'Paid' then v_reference
        else null
      end,
      "adminNote" = nullif(trim(coalesce(p_admin_note, '')), ''),
      "reviewedBy" = v_admin_id,
      "reviewedAt" = now()
  where id = v_request.id;

  select uid into v_user_uid
  from public.users
  where id = v_request."affiliateID";

  insert into public.notification_jobs (
    "eventType",
    title,
    body,
    payload
  ) values (
    'affiliate_payout_reviewed',
    'Payout request updated',
    case
      when v_status = 'Paid'
        then format('Your EGP %s payout was marked as paid.', v_request.amount)
      else format('Your EGP %s payout request was rejected.', v_request.amount)
    end,
    jsonb_build_object(
      'payout_request_id', v_request.id,
      'status', v_status,
      'target_user_uid', v_user_uid,
      'deep_link', '/affiliate'
    )
  );

  return jsonb_build_object(
    'id', v_request.id,
    'status', v_status
  );
end;
$$;

create or replace function public.sync_affiliate_payout_status()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status in ('Paid', 'Approved')
      and old.status is distinct from new.status then
    update public.affiliate_commissions
    set status = 'paid',
        "paidAt" = now()
    where "payoutRequestID" = new.id and status = 'processing';
  elsif new.status = 'Rejected'
      and old.status is distinct from new.status then
    update public.affiliate_commissions
    set status = 'available',
        "payoutRequestID" = null
    where "payoutRequestID" = new.id and status = 'processing';
  end if;
  return new;
end;
$$;

create or replace function public.enqueue_new_order_admin_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.notification_jobs (
    "eventType",
    title,
    body,
    payload
  ) values (
    'admin_order_placed',
    format('New order #%s', new.id),
    format('A new order for EGP %s has been placed.', new."totalPrice"),
    jsonb_build_object(
      'order_id', new.id,
      'target_audience', 'admins',
      'deep_link', '/admin-orders'
    )
  );
  return new;
end;
$$;

drop trigger if exists trg_enqueue_new_order_admin_notification
  on public.order_master;
create trigger trg_enqueue_new_order_admin_notification
after insert on public.order_master
for each row
execute function public.enqueue_new_order_admin_notification();

alter table public.affiliate_applications enable row level security;
revoke all on public.affiliate_applications from anon, authenticated;
revoke insert, update, delete on public.payout_requests
  from anon, authenticated;

revoke all on function public.submit_affiliate_application(text, text, text)
  from public, anon, authenticated;
revoke all on function public.review_affiliate_application(text, bigint, text, text)
  from public, anon, authenticated;
revoke all on function public.request_affiliate_payout(text, text, text)
  from public, anon, authenticated;
revoke all on function public.review_affiliate_payout(text, bigint, text, text, text)
  from public, anon, authenticated;

grant execute on function public.submit_affiliate_application(text, text, text)
  to service_role;
grant execute on function public.review_affiliate_application(text, bigint, text, text)
  to service_role;
grant execute on function public.request_affiliate_payout(text, text, text)
  to service_role;
grant execute on function public.review_affiliate_payout(text, bigint, text, text, text)
  to service_role;
