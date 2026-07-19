-- Keep localized item names as immutable order-detail snapshots.

alter table public.order_detail
  add column if not exists "itemNameEN" text;

update public.order_detail as detail
set "itemNameEN" = coalesce(
  nullif(trim(item."itemNameEN"), ''),
  nullif(trim(item."itemName"), ''),
  detail."itemName"
)
from public.item_properties as property
join public.items as item on item.id = property."itemID"
where detail."itemPropertyID" = property.id
  and nullif(trim(coalesce(detail."itemNameEN", '')), '') is null;

create or replace function public.populate_order_detail_item_names()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_name text;
  v_name_en text;
begin
  select item."itemName", item."itemNameEN"
  into v_name, v_name_en
  from public.item_properties as property
  join public.items as item on item.id = property."itemID"
  where property.id = new."itemPropertyID";

  if found then
    new."itemName" := coalesce(
      nullif(trim(new."itemName"), ''),
      nullif(trim(v_name), ''),
      nullif(trim(v_name_en), ''),
      ''
    );
    new."itemNameEN" := coalesce(
      nullif(trim(new."itemNameEN"), ''),
      nullif(trim(v_name_en), ''),
      nullif(trim(v_name), ''),
      new."itemName"
    );
  end if;

  return new;
end;
$$;

drop trigger if exists trg_populate_order_detail_item_names
  on public.order_detail;
create trigger trg_populate_order_detail_item_names
before insert or update of "itemPropertyID" on public.order_detail
for each row
execute function public.populate_order_detail_item_names();
