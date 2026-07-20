-- First-class bundle deals, bundle cart lines, order snapshots, and banner storage.

create table if not exists public.bundle_deals (
  id bigserial primary key,
  title text not null,
  "titleEN" text not null default '',
  description text not null default '',
  "descriptionEN" text not null default '',
  "bannerImage" text not null,
  "dealPrice" numeric(12, 2) not null check ("dealPrice" > 0),
  "isActive" boolean not null default true,
  "sortOrder" integer not null default 0,
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now()
);

create table if not exists public.bundle_deal_items (
  id bigserial primary key,
  "bundleID" bigint not null
    references public.bundle_deals(id) on delete cascade,
  "propertyID" bigint not null
    references public.item_properties(id),
  quantity integer not null check (quantity > 0),
  unique ("bundleID", "propertyID")
);

create index if not exists bundle_deals_home_order
  on public.bundle_deals ("isActive", "sortOrder", id desc);
create index if not exists bundle_deal_items_bundle
  on public.bundle_deal_items ("bundleID");

alter table public.bundle_deals enable row level security;
alter table public.bundle_deal_items enable row level security;

drop policy if exists "Public can read active bundle deals"
  on public.bundle_deals;
create policy "Public can read active bundle deals"
  on public.bundle_deals for select
  to anon, authenticated
  using ("isActive" = true);

drop policy if exists "Public can read active bundle items"
  on public.bundle_deal_items;
create policy "Public can read active bundle items"
  on public.bundle_deal_items for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.bundle_deals b
      where b.id = "bundleID" and b."isActive" = true
    )
  );

-- A cart row contains either a normal property or one whole bundle.
alter table public.cart
  alter column "propertyID" drop not null,
  add column if not exists "bundleID" bigint
    references public.bundle_deals(id) on delete cascade;

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'cart'
      and column_name = 'itemID'
  ) then
    execute 'alter table public.cart alter column "itemID" drop not null';
  end if;
end;
$$;

alter table public.cart
  drop constraint if exists cart_line_kind_check;
alter table public.cart
  add constraint cart_line_kind_check check (
    ("propertyID" is not null and "bundleID" is null)
    or ("propertyID" is null and "bundleID" is not null)
  );

create unique index if not exists cart_user_property_unique
  on public.cart ("userID", "propertyID")
  where "propertyID" is not null;
create unique index if not exists cart_user_bundle_unique
  on public.cart ("userID", "bundleID")
  where "bundleID" is not null;

alter table public.order_master
  add column if not exists "bundleSavings" numeric(12, 2)
    not null default 0;

alter table public.order_detail
  add column if not exists "bundleID" bigint,
  add column if not exists "bundleName" text,
  add column if not exists "bundleQuantity" integer,
  add column if not exists "bundleDealPrice" numeric(12, 2);

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'bundle_banner',
  'bundle_banner',
  true,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Public can view bundle banners"
  on storage.objects;
create policy "Public can view bundle banners"
  on storage.objects for select
  to public
  using (bucket_id = 'bundle_banner');

-- The function runs only behind the Firebase-verified affiliate-program
-- Edge Function. Every product price, bundle price, and stock flag is reloaded.
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
  v_regular_subtotal numeric(12, 2);
  v_bundle_savings numeric(12, 2) := 0;
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
    left join public.bundle_deals b on b.id = c."bundleID"
    where c."userID" = v_user_id
      and (
        c.quantity <= 0
        or (
          c."propertyID" is not null
          and (p.id is null or p."inStock" is not true)
        )
        or (
          c."bundleID" is not null
          and (
            b.id is null
            or b."isActive" is not true
            or not exists (
              select 1 from public.bundle_deal_items bi
              where bi."bundleID" = b.id
            )
            or exists (
              select 1
              from public.bundle_deal_items bi
              left join public.item_properties bp
                on bp.id = bi."propertyID"
              where bi."bundleID" = b.id
                and (bp.id is null or bp."inStock" is not true)
            )
          )
        )
      )
  ) then
    raise exception 'One or more cart items are unavailable';
  end if;

  select round(coalesce(sum(
    case
      when c."bundleID" is not null
        then c.quantity::numeric * b."dealPrice"
      else c.quantity::numeric * p.price::numeric
    end
  ), 0), 2)
  into v_subtotal
  from public.cart c
  left join public.item_properties p on p.id = c."propertyID"
  left join public.bundle_deals b on b.id = c."bundleID"
  where c."userID" = v_user_id;

  select round(coalesce(sum(
    case
      when c."bundleID" is not null then
        c.quantity::numeric * (
          select coalesce(sum(bi.quantity::numeric * bp.price::numeric), 0)
          from public.bundle_deal_items bi
          join public.item_properties bp on bp.id = bi."propertyID"
          where bi."bundleID" = c."bundleID"
        )
      else c.quantity::numeric * p.price::numeric
    end
  ), 0), 2)
  into v_regular_subtotal
  from public.cart c
  left join public.item_properties p on p.id = c."propertyID"
  where c."userID" = v_user_id;

  v_bundle_savings := greatest(0, v_regular_subtotal - v_subtotal);

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
      a.source as attribution_source,
      c.id as code_id
    into v_attribution
    from public.customer_affiliate_attributions a
    join public.affiliate_codes c on c.id = a."affiliateCodeID"
    where a."userID" = v_user_id
      and a."isActive" = true
      and a."expiresAt" > now()
      and c."isActive" = true
    order by a."attributedAt" desc
    limit 1;

    if v_attribution.code_id is not null then
      select * into v_code
      from public.affiliate_codes
      where id = v_attribution.code_id;
      v_attribution_id := v_attribution.attribution_id;
      v_requested_code := v_code.code;
      v_promo_type := 'affiliate';
      v_source := v_attribution.attribution_source;
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
    "bundleSavings",
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
    v_bundle_savings,
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
  where c."userID" = v_user_id
    and c."propertyID" is not null;

  insert into public.order_detail (
    "orderMasterID",
    "itemPropertyID",
    "itemName",
    quantity,
    price,
    "bundleID",
    "bundleName",
    "bundleQuantity",
    "bundleDealPrice"
  )
  select
    v_order_id,
    p.id,
    i."itemName",
    c.quantity * bi.quantity,
    p.price,
    b.id,
    b.title,
    c.quantity,
    b."dealPrice"
  from public.cart c
  join public.bundle_deals b on b.id = c."bundleID"
  join public.bundle_deal_items bi on bi."bundleID" = b.id
  join public.item_properties p on p.id = bi."propertyID"
  join public.items i on i.id = p."itemID"
  where c."userID" = v_user_id
    and c."bundleID" is not null;

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
    'regular_subtotal', v_regular_subtotal,
    'subtotal', v_subtotal,
    'bundle_savings', v_bundle_savings,
    'discount', v_discount,
    'total', v_total,
    'promo_code', nullif(v_requested_code, ''),
    'promo_type', v_promo_type,
    'affiliate_commission', v_commission
  );
end;
$$;

revoke all on function public.place_order_secure(
  text,
  bigint,
  text,
  text,
  text,
  text
) from public, anon, authenticated;
grant execute on function public.place_order_secure(
  text,
  bigint,
  text,
  text,
  text,
  text
) to service_role;
