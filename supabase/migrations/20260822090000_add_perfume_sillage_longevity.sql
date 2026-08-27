alter table public.items
  add column if not exists sillage integer not null default 3,
  add column if not exists longevity integer not null default 3;

alter table public.items
  drop constraint if exists items_sillage_range,
  drop constraint if exists items_longevity_range;

alter table public.items
  add constraint items_sillage_range check (sillage between 1 and 5),
  add constraint items_longevity_range check (longevity between 1 and 5);

update public.items
set sillage = 3,
    longevity = 3;

comment on column public.items.sillage is
  'Perfume sillage rating from 1 to 5.';
comment on column public.items.longevity is
  'Perfume longevity rating from 1 to 5.';
