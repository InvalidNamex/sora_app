alter table public.address_book
  add column if not exists "addressName" text;
