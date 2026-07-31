create table public.item_suggestions (
  id bigserial primary key,
  user_id bigint not null references public.users(id) on delete cascade,
  item_name text not null,
  brand_name text,
  details text,
  status text not null default 'pending',
  admin_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint item_suggestions_item_name_not_empty
    check (length(trim(item_name)) between 2 and 160),
  constraint item_suggestions_brand_name_length
    check (brand_name is null or length(brand_name) <= 160),
  constraint item_suggestions_details_length
    check (details is null or length(details) <= 2000),
  constraint item_suggestions_admin_note_length
    check (admin_note is null or length(admin_note) <= 2000),
  constraint item_suggestions_status_valid
    check (status in ('pending', 'approved', 'rejected'))
);

create index item_suggestions_user_created_idx
  on public.item_suggestions (user_id, created_at desc);

create index item_suggestions_status_created_idx
  on public.item_suggestions (status, created_at desc);

alter table public.item_suggestions enable row level security;

-- Access is deliberately service-role-only. The item-suggestions Edge
-- Function verifies Firebase ID tokens before every user or admin operation.
revoke all on public.item_suggestions from anon, authenticated;
revoke all on sequence public.item_suggestions_id_seq from anon, authenticated;
