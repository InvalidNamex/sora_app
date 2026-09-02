-- Item-property discounts, order snapshots, and automatic discounted sections.

alter table public.item_properties
  add column if not exists "discountPercentage" double precision not null default 0;

alter table public.item_properties
  drop constraint if exists item_properties_discount_percentage_check;
alter table public.item_properties
  add constraint item_properties_discount_percentage_check
  check ("discountPercentage" between 0 and 100);

alter table public.order_master
  add column if not exists "itemDiscount" double precision not null default 0;

alter table public.order_detail
  add column if not exists "regularPrice" double precision,
  add column if not exists "itemDiscountPercentage" double precision;

alter table public.home_sections
  drop constraint if exists home_sections_section_type_check;
alter table public.home_sections
  add constraint home_sections_section_type_check
  check (section_type in ('manual', 'recently_added', 'discounted'));

notify pgrst, 'reload schema';

create or replace function public.item_property_sale_price(
  p_price double precision,
  p_discount double precision
)
returns numeric
language sql
immutable
parallel safe
as $$
  select round((
    greatest(0, coalesce(p_price, 0)) *
      (1 - greatest(0, least(100, coalesce(p_discount, 0))) / 100)
  )::numeric, 2);
$$;

revoke all on function public.item_property_sale_price(double precision, double precision)
  from public, anon, authenticated;
grant execute on function public.item_property_sale_price(double precision, double precision)
  to service_role;

-- Layer the item discount into the existing bundle-aware secure checkout RPC.
-- The RPC recomputes every price from item_properties, so checkout totals and
-- the order snapshot cannot be changed by a client request.
do $migration$
declare
  v_definition text;
  v_declaration_marker constant text :=
    '  v_requested_code text := upper(trim(coalesce(p_promo_code, '''')));';
  v_subtotal_marker constant text :=
    E'  select round(coalesce(sum(\n' ||
    E'    case\n' ||
    E'      when c."bundleID" is not null\n' ||
    E'        then c.quantity::numeric * b."dealPrice"\n' ||
    E'      else c.quantity::numeric * p.price::numeric\n' ||
    E'    end\n' ||
    E'  ), 0), 2)\n' ||
    E'  into v_subtotal';
  v_savings_marker constant text :=
    E'  v_bundle_savings := greatest(0, v_regular_subtotal - v_subtotal);';
  v_total_discount_marker constant text :=
    E'  v_discount := greatest(0, least(v_subtotal, v_discount));';
  v_order_columns_marker constant text :=
    E'    "totalDiscount",\n    "bundleSavings",';
  v_order_values_marker constant text :=
    E'    v_total,\n    v_discount,\n    v_bundle_savings,';
  v_detail_columns_marker constant text :=
    E'    "itemName",\n' ||
    E'    quantity,\n' ||
    E'    price\n' ||
    E'  )\n' ||
    E'  select';
  v_detail_values_marker constant text :=
    E'    i."itemName",\n' ||
    E'    c.quantity,\n' ||
    E'    p.price\n' ||
    E'  from public.cart c';
begin
  select pg_get_functiondef(
    'public.place_order_secure(text,bigint,text,text,text,text)'::regprocedure
  ) into v_definition;

  if v_definition is null then
    raise exception 'place_order_secure is not installed';
  end if;

  if position('v_eligible_subtotal numeric' in v_definition) > 0 then
    return;
  end if;

  if position(v_declaration_marker in v_definition) = 0
    or position(v_subtotal_marker in v_definition) = 0
    or position(v_savings_marker in v_definition) = 0
    or position(v_total_discount_marker in v_definition) = 0
    or position(v_order_columns_marker in v_definition) = 0
    or position(v_order_values_marker in v_definition) = 0
    or position(v_detail_columns_marker in v_definition) = 0
    or position(v_detail_values_marker in v_definition) = 0 then
    raise exception
      'Unexpected place_order_secure definition; item discounts not applied';
  end if;

  v_definition := replace(
    v_definition,
    v_declaration_marker,
    v_declaration_marker || E'\n  v_eligible_subtotal numeric(12, 2);\n' ||
      '  v_item_discount numeric(12, 2) := 0;'
  );

  v_definition := replace(
    v_definition,
    v_subtotal_marker,
    replace(
      v_subtotal_marker,
      'else c.quantity::numeric * p.price::numeric',
      'else c.quantity::numeric * public.item_property_sale_price(p.price, p."discountPercentage")'
    )
  );

  v_definition := replace(
    v_definition,
    v_savings_marker,
    E'  select round(coalesce(sum(\n' ||
      E'    case when c."bundleID" is null then\n' ||
      E'      c.quantity::numeric * greatest(0, p.price::numeric - public.item_property_sale_price(p.price, p."discountPercentage"))\n' ||
      E'    else 0 end\n' ||
      E'  ), 0), 2)\n' ||
      E'  into v_item_discount\n' ||
      E'  from public.cart c\n' ||
      E'  join public.item_properties p on p.id = c."propertyID"\n' ||
      E'  where c."userID" = v_user_id;\n\n' ||
      E'  select round(coalesce(sum(\n' ||
      E'    case when c."bundleID" is null and public.item_property_sale_price(p.price, p."discountPercentage") >= p.price::numeric then\n' ||
      E'      c.quantity::numeric * p.price::numeric\n' ||
      E'    else 0 end\n' ||
      E'  ), 0), 2)\n' ||
      E'  into v_eligible_subtotal\n' ||
      E'  from public.cart c\n' ||
      E'  join public.item_properties p on p.id = c."propertyID"\n' ||
      E'  where c."userID" = v_user_id;\n\n' ||
      '  v_bundle_savings := greatest(0, v_regular_subtotal - v_subtotal - v_item_discount);'
  );

  v_definition := replace(v_definition, 'v_subtotal * v_code."customerDiscountPercentage"',
    'v_eligible_subtotal * v_code."customerDiscountPercentage"');
  v_definition := replace(v_definition, E'least(\n            v_subtotal,', E'least(\n            v_eligible_subtotal,');
  v_definition := replace(v_definition, 'v_subtotal * v_voucher."voucherPercentage"',
    'v_eligible_subtotal * v_voucher."voucherPercentage"');

  v_definition := replace(
    v_definition,
    v_order_columns_marker,
    E'    "totalDiscount",\n    "itemDiscount",\n    "bundleSavings",'
  );
  v_definition := replace(
    v_definition,
    v_order_values_marker,
    E'    v_total,\n    v_discount + v_item_discount,\n    v_item_discount,\n    v_bundle_savings,'
  );

  v_definition := replace(
    v_definition,
    v_detail_columns_marker,
    E'    "itemName",\n' ||
      E'    quantity,\n' ||
      E'    price,\n' ||
      E'    "regularPrice",\n' ||
      E'    "itemDiscountPercentage"\n' ||
      E'  )\n' ||
      E'  select'
  );
  v_definition := replace(
    v_definition,
    v_detail_values_marker,
    E'    i."itemName",\n' ||
      E'    c.quantity,\n' ||
      E'    public.item_property_sale_price(p.price, p."discountPercentage"),\n' ||
      E'    p.price,\n' ||
      E'    p."discountPercentage"\n' ||
      E'  from public.cart c'
  );

  v_definition := replace(
    v_definition,
    E'      v_subtotal,\n' ||
    E'      v_discount,\n' ||
    E'      v_code."affiliateCommissionPercentage",',
    E'      v_eligible_subtotal,\n' ||
    E'      v_discount,\n' ||
    E'      v_code."affiliateCommissionPercentage",'
  );

  execute v_definition;
end;
$migration$;
