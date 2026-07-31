alter table public.items
  add column if not exists "brandName" text not null default '';

comment on column public.items."brandName" is
  'Perfume or product brand display name.';
