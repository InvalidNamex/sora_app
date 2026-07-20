-- App Store-compliant account deletion with order-safe anonymization.

alter table public.users
  add column if not exists email text,
  add column if not exists "phoneTwo" text,
  add column if not exists "fcmTokens" text,
  add column if not exists "isDeleted" boolean not null default false,
  add column if not exists "deletedAt" timestamptz;

create or replace function public.begin_account_deletion(p_user_uid text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id bigint;
begin
  select id into v_user_id
  from public.users
  where uid = p_user_uid
  for update;

  if v_user_id is null then
    raise exception 'Account profile not found';
  end if;

  -- Shopping and preference data has no legal/order retention purpose.
  delete from public.cart where "userID" = v_user_id;

  if to_regclass('public.liked_items') is not null then
    execute 'delete from public.liked_items where "userID" = $1'
      using v_user_id;
  end if;

  if to_regclass('public.device_tokens') is not null then
    execute 'delete from public.device_tokens where "userID" = $1'
      using p_user_uid;
  end if;

  if to_regclass('public.customer_affiliate_attributions') is not null then
    execute
      'delete from public.customer_affiliate_attributions where "userID" = $1'
      using v_user_id;
  end if;

  if to_regclass('public.affiliate_applications') is not null then
    execute
      'delete from public.affiliate_applications where "userID" = $1'
      using v_user_id;
  end if;

  -- Addresses referenced by an order must remain as FK placeholders. Their
  -- personal content is removed; unreferenced address rows are deleted.
  delete from public.address_book address_row
  where address_row."userID" = v_user_id
    and not exists (
      select 1
      from public.order_master order_row
      where order_row."addressID" = address_row.id
    );

  update public.address_book
  set
    "addressName" = 'Deleted address',
    address = '',
    landmark = null
  where "userID" = v_user_id;

  -- Completed and otherwise final orders no longer need delivery PII. Active
  -- orders retain only their order snapshot until fulfilment reaches a final
  -- status, when the trigger below performs the same redaction.
  update public.order_master
  set
    address = '',
    "phoneNumber" = '',
    notes = null
  where "userID" = v_user_id
    and "orderStatus" in ('Delivered', 'Cancelled', 'Returned');

  -- Affiliate financial ledgers are retained for accounting, while active
  -- marketing access and payout destinations are removed.
  if to_regclass('public.affiliate_codes') is not null then
    execute
      'update public.affiliate_codes
       set "isActive" = false, "updatedAt" = now()
       where "affiliateID" = $1'
      using v_user_id;
  end if;

  if to_regclass('public.payout_requests') is not null
    and exists (
      select 1
      from information_schema.columns
      where table_schema = 'public'
        and table_name = 'payout_requests'
        and column_name = 'payoutAccount'
    )
  then
    execute
      'update public.payout_requests
       set "payoutAccount" = null
       where "affiliateID" = $1'
      using v_user_id;
  end if;

  update public.users
  set
    name = 'Deleted User',
    phone = '',
    "phoneTwo" = null,
    email = null,
    "isAffiliate" = false,
    "isAdmin" = false,
    "fcmTokens" = null,
    "isDeleted" = true,
    "deletedAt" = now()
  where id = v_user_id;

  return jsonb_build_object(
    'user_id', v_user_id,
    'deleted_at', now()
  );
end;
$$;

create or replace function public.finalize_account_deletion(p_user_uid text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_updated_count integer;
begin
  update public.users
  set uid =
    'deleted:' || id::text || ':' ||
    md5(p_user_uid || ':' || clock_timestamp()::text)
  where uid = p_user_uid
    and "isDeleted" = true;

  get diagnostics v_updated_count = row_count;
  return v_updated_count > 0;
end;
$$;

create or replace function public.redact_deleted_user_order_pii()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new."orderStatus" in ('Delivered', 'Cancelled', 'Returned')
    and old."orderStatus" is distinct from new."orderStatus"
    and exists (
      select 1
      from public.users
      where id = new."userID"
        and "isDeleted" = true
    )
  then
    new.address := '';
    new."phoneNumber" := '';
    new.notes := null;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_redact_deleted_user_order_pii
  on public.order_master;
create trigger trg_redact_deleted_user_order_pii
before update of "orderStatus" on public.order_master
for each row
execute function public.redact_deleted_user_order_pii();

revoke all on function public.begin_account_deletion(text)
  from public, anon, authenticated;
revoke all on function public.finalize_account_deletion(text)
  from public, anon, authenticated;
grant execute on function public.begin_account_deletion(text)
  to service_role;
grant execute on function public.finalize_account_deletion(text)
  to service_role;
