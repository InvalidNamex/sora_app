-- Affiliate codes, durable attribution, commission ledger, and secure checkout.

create table if not exists public.affiliate_codes (
  id bigserial primary key,
  "affiliateID" bigint not null unique references public.users(id) on delete cascade,
  code text not null,
  "customerDiscountPercentage" numeric(5, 2) not null default 10,
  "affiliateCommissionPercentage" numeric(5, 2) not null default 15,
  "isActive" boolean not null default true,
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now(),
  constraint affiliate_codes_code_format
    check (code ~ '^[A-Z0-9]{4,20}$'),
  constraint affiliate_codes_customer_discount_range
    check ("customerDiscountPercentage" between 0 and 100),
  constraint affiliate_codes_commission_range
    check ("affiliateCommissionPercentage" between 0 and 100)
);

create unique index if not exists affiliate_codes_code_upper_unique
  on public.affiliate_codes (upper(code));

create table if not exists public.customer_affiliate_attributions (
  id bigserial primary key,
  "userID" bigint not null references public.users(id) on delete cascade,
  "affiliateCodeID" bigint not null references public.affiliate_codes(id),
  source text not null check (source in ('link', 'manual')),
  "itemID" bigint references public.items(id) on delete set null,
  "attributedAt" timestamptz not null default now(),
  "expiresAt" timestamptz not null default (now() + interval '30 days'),
  "convertedOrderID" bigint,
  "isActive" boolean not null default true
);

create unique index if not exists customer_affiliate_one_active
  on public.customer_affiliate_attributions ("userID")
  where "isActive";

create index if not exists customer_affiliate_attribution_lookup
  on public.customer_affiliate_attributions ("userID", "isActive", "expiresAt");

alter table public.order_master
  add column if not exists "affiliateCodeID" bigint references public.affiliate_codes(id),
  add column if not exists "affiliateCode" text,
  add column if not exists "affiliateSource" text,
  add column if not exists "affiliateDiscountPercentage" numeric(5, 2),
  add column if not exists "affiliateCommissionPercentage" numeric(5, 2),
  add column if not exists "affiliateCommissionAmount" numeric(12, 2) not null default 0,
  add column if not exists "appliedPromoCode" text,
  add column if not exists "promoType" text;

create table if not exists public.affiliate_commissions (
  id bigserial primary key,
  "affiliateID" bigint not null references public.users(id),
  "orderID" bigint not null unique references public.order_master(id) on delete cascade,
  "affiliateCodeID" bigint not null references public.affiliate_codes(id),
  source text not null check (source in ('link', 'manual')),
  "eligibleSubtotal" numeric(12, 2) not null,
  "customerDiscountAmount" numeric(12, 2) not null,
  "commissionPercentage" numeric(5, 2) not null,
  amount numeric(12, 2) not null,
  status text not null default 'pending'
    check (status in ('pending', 'available', 'processing', 'paid', 'void')),
  "payoutRequestID" bigint references public.payout_requests(id) on delete set null,
  "createdAt" timestamptz not null default now(),
  "availableAt" timestamptz,
  "paidAt" timestamptz
);

create index if not exists affiliate_commissions_balance
  on public.affiliate_commissions ("affiliateID", status);

create or replace function public.ensure_affiliate_code()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new."isAffiliate" = true then
    insert into public.affiliate_codes ("affiliateID", code, "isActive")
    values (new.id, 'SORA' || new.id::text, true)
    on conflict ("affiliateID")
    do update set
      "isActive" = true,
      "updatedAt" = now();
  elsif old."isAffiliate" = true and new."isAffiliate" = false then
    update public.affiliate_codes
    set "isActive" = false, "updatedAt" = now()
    where "affiliateID" = new.id;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_ensure_affiliate_code on public.users;
create trigger trg_ensure_affiliate_code
after update of "isAffiliate" on public.users
for each row
execute function public.ensure_affiliate_code();

insert into public.affiliate_codes ("affiliateID", code)
select id, 'SORA' || id::text
from public.users
where "isAffiliate" = true
on conflict ("affiliateID") do nothing;

alter table public.item_properties
  drop column if exists "affiliatePercentage";

create or replace function public.save_affiliate_attribution(
  p_user_uid text,
  p_code text,
  p_source text default 'link',
  p_item_id bigint default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id bigint;
  v_code public.affiliate_codes%rowtype;
  v_source text := case when p_source = 'manual' then 'manual' else 'link' end;
begin
  select id into v_user_id
  from public.users
  where uid = p_user_uid;

  if v_user_id is null then
    raise exception 'User profile not found';
  end if;

  select * into v_code
  from public.affiliate_codes
  where upper(code) = upper(trim(p_code))
    and "isActive" = true;

  if v_code.id is null then
    raise exception 'Invalid affiliate code';
  end if;

  if v_code."affiliateID" = v_user_id then
    raise exception 'Affiliates cannot use their own code';
  end if;

  update public.customer_affiliate_attributions
  set "isActive" = false
  where "userID" = v_user_id and "isActive" = true;

  insert into public.customer_affiliate_attributions (
    "userID",
    "affiliateCodeID",
    source,
    "itemID"
  ) values (
    v_user_id,
    v_code.id,
    v_source,
    p_item_id
  );

  return jsonb_build_object(
    'code', v_code.code,
    'customer_discount_percentage', v_code."customerDiscountPercentage",
    'expires_at', now() + interval '30 days'
  );
end;
$$;

create or replace function public.place_order_secure(
  p_user_uid text,
  p_address_id bigint,
  p_phone text,
  p_notes text default '',
  p_promo_code text default null,
  p_affiliate_source text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id bigint;
  v_address text;
  v_subtotal numeric(12, 2);
  v_discount numeric(12, 2) := 0;
  v_total numeric(12, 2);
  v_commission numeric(12, 2) := 0;
  v_requested_code text := upper(trim(coalesce(p_promo_code, '')));
  v_promo_type text;
  v_source text;
  v_code public.affiliate_codes%rowtype;
  v_voucher record;
  v_promotion record;
  v_attribution record;
  v_order_id bigint;
  v_attribution_id bigint;
begin
  select id into v_user_id
  from public.users
  where uid = p_user_uid;

  if v_user_id is null then
    raise exception 'User profile not found';
  end if;

  select concat_ws(
    ' - ',
    nullif(trim(coalesce(address, '')), ''),
    nullif(trim(coalesce(landmark, '')), '')
  )
  into v_address
  from public.address_book
  where id = p_address_id and "userID" = v_user_id;

  if v_address is null or v_address = '' then
    raise exception 'Invalid delivery address';
  end if;

  if trim(coalesce(p_phone, '')) = '' then
    raise exception 'Phone number is required';
  end if;

  if not exists (
    select 1 from public.cart where "userID" = v_user_id
  ) then
    raise exception 'Cart is empty';
  end if;

  if exists (
    select 1
    from public.cart c
    left join public.item_properties p on p.id = c."propertyID"
    where c."userID" = v_user_id
      and (
        p.id is null
        or p."inStock" is not true
        or c.quantity <= 0
      )
  ) then
    raise exception 'One or more cart items are unavailable';
  end if;

  select round(sum(c.quantity::numeric * p.price::numeric), 2)
  into v_subtotal
  from public.cart c
  join public.item_properties p on p.id = c."propertyID"
  where c."userID" = v_user_id;

  if v_requested_code <> '' then
    select * into v_code
    from public.affiliate_codes
    where upper(code) = v_requested_code
      and "isActive" = true;

    if v_code.id is not null then
      if v_code."affiliateID" = v_user_id then
        raise exception 'Affiliates cannot use their own code';
      end if;
      v_promo_type := 'affiliate';
      v_source := case
        when p_affiliate_source = 'link' then 'link'
        else 'manual'
      end;
      v_discount := round(
        v_subtotal * v_code."customerDiscountPercentage" / 100,
        2
      );
    else
      select * into v_voucher
      from public.vouchers
      where upper("voucherCode") = v_requested_code
        and "isActive" = true;

      if found then
        v_promo_type := 'voucher';
        if v_voucher."voucherAmount" is not null then
          v_discount := least(
            v_subtotal,
            round(v_voucher."voucherAmount"::numeric, 2)
          );
        elsif v_voucher."voucherPercentage" is not null then
          v_discount := round(
            v_subtotal * v_voucher."voucherPercentage"::numeric / 100,
            2
          );
        end if;
      else
        select * into v_promotion
        from public.promotions
        where upper("promotionCode") = v_requested_code
          and ("expiry_date" is null or "expiry_date" > now());

        if found then
          v_promo_type := 'promotion';
          v_discount := least(
            v_subtotal,
            round(v_promotion."promotionDiscount"::numeric, 2)
          );
        else
          raise exception 'Invalid promo code';
        end if;
      end if;
    end if;
  else
    select
      a.id as attribution_id,
      a.source,
      c.*
    into v_attribution
    from public.customer_affiliate_attributions a
    join public.affiliate_codes c on c.id = a."affiliateCodeID"
    where a."userID" = v_user_id
      and a."isActive" = true
      and a."expiresAt" > now()
      and c."isActive" = true
    order by a."attributedAt" desc
    limit 1;

    if v_attribution.id is not null then
      select * into v_code
      from public.affiliate_codes
      where id = v_attribution.id;
      v_attribution_id := v_attribution.attribution_id;
      v_requested_code := v_code.code;
      v_promo_type := 'affiliate';
      v_source := v_attribution.source;
      v_discount := round(
        v_subtotal * v_code."customerDiscountPercentage" / 100,
        2
      );
    end if;
  end if;

  v_discount := greatest(0, least(v_subtotal, v_discount));
  v_total := round(v_subtotal - v_discount, 2);

  if v_code.id is not null then
    v_commission := round(
      v_total * v_code."affiliateCommissionPercentage" / 100,
      2
    );
  end if;

  insert into public.order_master (
    "userID",
    "addressID",
    address,
    "phoneNumber",
    "affiliateID",
    "affiliateCodeID",
    "affiliateCode",
    "affiliateSource",
    "affiliateDiscountPercentage",
    "affiliateCommissionPercentage",
    "affiliateCommissionAmount",
    "appliedPromoCode",
    "promoType",
    "totalPrice",
    "totalDiscount",
    notes,
    "orderStatus"
  ) values (
    v_user_id,
    p_address_id,
    v_address,
    trim(p_phone),
    v_code."affiliateID",
    v_code.id,
    v_code.code,
    v_source,
    v_code."customerDiscountPercentage",
    v_code."affiliateCommissionPercentage",
    v_commission,
    nullif(v_requested_code, ''),
    v_promo_type,
    v_total,
    v_discount,
    trim(coalesce(p_notes, '')),
    'Pending'
  )
  returning id into v_order_id;

  insert into public.order_detail (
    "orderMasterID",
    "itemPropertyID",
    "itemName",
    quantity,
    price
  )
  select
    v_order_id,
    p.id,
    i."itemName",
    c.quantity,
    p.price
  from public.cart c
  join public.item_properties p on p.id = c."propertyID"
  join public.items i on i.id = p."itemID"
  where c."userID" = v_user_id;

  if v_code.id is not null then
    insert into public.affiliate_commissions (
      "affiliateID",
      "orderID",
      "affiliateCodeID",
      source,
      "eligibleSubtotal",
      "customerDiscountAmount",
      "commissionPercentage",
      amount
    ) values (
      v_code."affiliateID",
      v_order_id,
      v_code.id,
      v_source,
      v_subtotal,
      v_discount,
      v_code."affiliateCommissionPercentage",
      v_commission
    );

    if v_attribution_id is null then
      select id into v_attribution_id
      from public.customer_affiliate_attributions
      where "userID" = v_user_id
        and "affiliateCodeID" = v_code.id
        and "isActive" = true
      order by "attributedAt" desc
      limit 1;
    end if;

    update public.customer_affiliate_attributions
    set "isActive" = false,
        "convertedOrderID" = case
          when id = v_attribution_id then v_order_id
          else "convertedOrderID"
        end
    where "userID" = v_user_id and "isActive" = true;

    if v_attribution_id is null then
      insert into public.customer_affiliate_attributions (
        "userID",
        "affiliateCodeID",
        source,
        "convertedOrderID",
        "isActive"
      ) values (
        v_user_id,
        v_code.id,
        v_source,
        v_order_id,
        false
      );
    end if;
  end if;

  delete from public.cart where "userID" = v_user_id;

  return jsonb_build_object(
    'order_id', v_order_id,
    'subtotal', v_subtotal,
    'discount', v_discount,
    'total', v_total,
    'promo_code', nullif(v_requested_code, ''),
    'promo_type', v_promo_type,
    'affiliate_commission', v_commission
  );
end;
$$;

create or replace function public.request_affiliate_payout(p_user_uid text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_affiliate_id bigint;
  v_amount numeric(12, 2);
  v_request_id bigint;
begin
  select id into v_affiliate_id
  from public.users
  where uid = p_user_uid and "isAffiliate" = true;

  if v_affiliate_id is null then
    raise exception 'Affiliate profile not found';
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

  insert into public.payout_requests ("affiliateID", amount, status)
  values (v_affiliate_id, v_amount, 'Pending')
  returning id into v_request_id;

  update public.affiliate_commissions
  set status = 'processing',
      "payoutRequestID" = v_request_id
  where "affiliateID" = v_affiliate_id and status = 'available';

  return jsonb_build_object(
    'payout_request_id', v_request_id,
    'amount', v_amount
  );
end;
$$;

create or replace function public.sync_affiliate_commission_status()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new."orderStatus" = 'Delivered'
    and old."orderStatus" is distinct from new."orderStatus" then
    update public.affiliate_commissions
    set status = 'available',
        "availableAt" = now()
    where "orderID" = new.id and status = 'pending';
  elsif new."orderStatus" in ('Cancelled', 'Returned')
    and old."orderStatus" is distinct from new."orderStatus" then
    update public.affiliate_commissions
    set status = 'void'
    where "orderID" = new.id and status in ('pending', 'available');
  end if;
  return new;
end;
$$;

drop trigger if exists trg_sync_affiliate_commission_status
  on public.order_master;
create trigger trg_sync_affiliate_commission_status
after update of "orderStatus" on public.order_master
for each row
execute function public.sync_affiliate_commission_status();

create or replace function public.sync_affiliate_payout_status()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'Approved' and old.status is distinct from new.status then
    update public.affiliate_commissions
    set status = 'paid',
        "paidAt" = now()
    where "payoutRequestID" = new.id and status = 'processing';
  elsif new.status = 'Rejected' and old.status is distinct from new.status then
    update public.affiliate_commissions
    set status = 'available',
        "payoutRequestID" = null
    where "payoutRequestID" = new.id and status = 'processing';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_sync_affiliate_payout_status
  on public.payout_requests;
create trigger trg_sync_affiliate_payout_status
after update of status on public.payout_requests
for each row
execute function public.sync_affiliate_payout_status();

alter table public.affiliate_codes enable row level security;
alter table public.customer_affiliate_attributions enable row level security;
alter table public.affiliate_commissions enable row level security;

revoke all on public.affiliate_codes from anon, authenticated;
revoke all on public.customer_affiliate_attributions from anon, authenticated;
revoke all on public.affiliate_commissions from anon, authenticated;

revoke all on function public.save_affiliate_attribution(text, text, text, bigint)
  from public, anon, authenticated;
revoke all on function public.place_order_secure(text, bigint, text, text, text, text)
  from public, anon, authenticated;
revoke all on function public.request_affiliate_payout(text)
  from public, anon, authenticated;

grant execute on function public.save_affiliate_attribution(text, text, text, bigint)
  to service_role;
grant execute on function public.place_order_secure(text, bigint, text, text, text, text)
  to service_role;
grant execute on function public.request_affiliate_payout(text)
  to service_role;
