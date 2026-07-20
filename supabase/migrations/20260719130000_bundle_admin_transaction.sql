-- Save bundle metadata and its fixed recipe in one database transaction.

create or replace function public.admin_save_bundle(
  p_bundle_id bigint,
  p_bundle jsonb,
  p_items jsonb
)
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  v_bundle_id bigint;
begin
  if trim(coalesce(p_bundle ->> 'title', '')) = ''
    or trim(coalesce(p_bundle ->> 'bannerImage', '')) = ''
    or coalesce((p_bundle ->> 'dealPrice')::numeric, 0) <= 0
    or jsonb_typeof(p_items) <> 'array'
    or jsonb_array_length(p_items) = 0 then
    raise exception 'Complete all required bundle fields';
  end if;

  if p_bundle_id is null then
    insert into public.bundle_deals (
      title,
      "titleEN",
      description,
      "descriptionEN",
      "bannerImage",
      "dealPrice",
      "isActive",
      "sortOrder"
    ) values (
      trim(p_bundle ->> 'title'),
      trim(coalesce(p_bundle ->> 'titleEN', '')),
      trim(coalesce(p_bundle ->> 'description', '')),
      trim(coalesce(p_bundle ->> 'descriptionEN', '')),
      trim(p_bundle ->> 'bannerImage'),
      (p_bundle ->> 'dealPrice')::numeric,
      coalesce((p_bundle ->> 'isActive')::boolean, true),
      coalesce((p_bundle ->> 'sortOrder')::integer, 0)
    )
    returning id into v_bundle_id;
  else
    update public.bundle_deals
    set title = trim(p_bundle ->> 'title'),
        "titleEN" = trim(coalesce(p_bundle ->> 'titleEN', '')),
        description = trim(coalesce(p_bundle ->> 'description', '')),
        "descriptionEN" = trim(coalesce(p_bundle ->> 'descriptionEN', '')),
        "bannerImage" = trim(p_bundle ->> 'bannerImage'),
        "dealPrice" = (p_bundle ->> 'dealPrice')::numeric,
        "isActive" = coalesce((p_bundle ->> 'isActive')::boolean, true),
        "sortOrder" = coalesce((p_bundle ->> 'sortOrder')::integer, 0),
        "updatedAt" = now()
    where id = p_bundle_id
    returning id into v_bundle_id;

    if v_bundle_id is null then
      raise exception 'Bundle not found';
    end if;

    delete from public.bundle_deal_items
    where "bundleID" = v_bundle_id;
  end if;

  insert into public.bundle_deal_items (
    "bundleID",
    "propertyID",
    quantity
  )
  select
    v_bundle_id,
    item."propertyID",
    item.quantity
  from jsonb_to_recordset(p_items) as item(
    "propertyID" bigint,
    quantity integer
  );

  return v_bundle_id;
end;
$$;

revoke all on function public.admin_save_bundle(bigint, jsonb, jsonb)
  from public, anon, authenticated;
grant execute on function public.admin_save_bundle(bigint, jsonb, jsonb)
  to service_role;
