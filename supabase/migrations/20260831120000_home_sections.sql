create table if not exists public.home_sections (
  id bigserial primary key,
  title text not null check (length(trim(title)) > 0),
  "titleEN" text not null default '',
  section_type text not null default 'manual'
    check (section_type in ('manual', 'recently_added')),
  item_limit integer not null default 10 check (item_limit between 1 and 30),
  display_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.home_section_items (
  section_id bigint not null references public.home_sections(id) on delete cascade,
  "itemID" bigint not null references public.items(id) on delete cascade,
  display_order integer not null default 0,
  primary key (section_id, "itemID")
);

create index if not exists home_sections_active_order_idx
  on public.home_sections (is_active, display_order, id);
create index if not exists home_section_items_order_idx
  on public.home_section_items (section_id, display_order, "itemID");

insert into public.home_sections (title, "titleEN", section_type, item_limit, display_order)
select 'أضيف حديثاً', 'Recently Added', 'recently_added', 10, 0
where not exists (
  select 1 from public.home_sections where section_type = 'recently_added'
);

alter table public.home_sections enable row level security;
alter table public.home_section_items enable row level security;

drop policy if exists "Anyone can read active home sections" on public.home_sections;
create policy "Anyone can read active home sections"
on public.home_sections for select to anon, authenticated using (is_active = true);

drop policy if exists "Admins can read all home sections" on public.home_sections;
create policy "Admins can read all home sections"
on public.home_sections for select to authenticated
using (exists (select 1 from public.users where users.uid = (select auth.jwt() ->> 'sub') and users."isAdmin" = true));

drop policy if exists "Anyone can read home section items" on public.home_section_items;
create policy "Anyone can read home section items"
on public.home_section_items for select to anon, authenticated using (true);

drop policy if exists "Admins manage home sections" on public.home_sections;
create policy "Admins manage home sections"
on public.home_sections for all to authenticated
using (exists (select 1 from public.users where users.uid = (select auth.jwt() ->> 'sub') and users."isAdmin" = true))
with check (exists (select 1 from public.users where users.uid = (select auth.jwt() ->> 'sub') and users."isAdmin" = true));

drop policy if exists "Admins manage home section items" on public.home_section_items;
create policy "Admins manage home section items"
on public.home_section_items for all to authenticated
using (exists (select 1 from public.users where users.uid = (select auth.jwt() ->> 'sub') and users."isAdmin" = true))
with check (exists (select 1 from public.users where users.uid = (select auth.jwt() ->> 'sub') and users."isAdmin" = true));

grant select on public.home_sections, public.home_section_items to anon, authenticated;
grant insert, update, delete on public.home_sections, public.home_section_items to authenticated;
grant usage, select on sequence public.home_sections_id_seq to authenticated;

drop trigger if exists bump_home_content_version_on_home_sections on public.home_sections;
create trigger bump_home_content_version_on_home_sections
after insert or update or delete or truncate on public.home_sections
for each statement execute function public.bump_home_content_version();

drop trigger if exists bump_home_content_version_on_home_section_items on public.home_section_items;
create trigger bump_home_content_version_on_home_section_items
after insert or update or delete or truncate on public.home_section_items
for each statement execute function public.bump_home_content_version();
