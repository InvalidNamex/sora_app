create table if not exists public.video_ads (
  id bigserial primary key,
  "videoURL" text not null,
  "isVertical" boolean not null default true,
  "itemID" bigint not null references public.items(id) on delete cascade,
  constraint video_ads_video_url_not_empty check (length(trim("videoURL")) > 0)
);

alter table public.video_ads enable row level security;

drop policy if exists "Anyone can read video ads" on public.video_ads;
create policy "Anyone can read video ads"
on public.video_ads
for select
to anon, authenticated
using (true);

drop policy if exists "Admins can insert video ads" on public.video_ads;
create policy "Admins can insert video ads"
on public.video_ads
for insert
to authenticated
with check (
  exists (
    select 1
    from public.users
    where users.uid = (select auth.jwt() ->> 'sub')
      and users."isAdmin" = true
  )
);

drop policy if exists "Admins can update video ads" on public.video_ads;
create policy "Admins can update video ads"
on public.video_ads
for update
to authenticated
using (
  exists (
    select 1
    from public.users
    where users.uid = (select auth.jwt() ->> 'sub')
      and users."isAdmin" = true
  )
)
with check (
  exists (
    select 1
    from public.users
    where users.uid = (select auth.jwt() ->> 'sub')
      and users."isAdmin" = true
  )
);

drop policy if exists "Admins can delete video ads" on public.video_ads;
create policy "Admins can delete video ads"
on public.video_ads
for delete
to authenticated
using (
  exists (
    select 1
    from public.users
    where users.uid = (select auth.jwt() ->> 'sub')
      and users."isAdmin" = true
  )
);

grant select on public.video_ads to anon, authenticated;
grant insert, update, delete on public.video_ads to authenticated;
grant usage, select on sequence public.video_ads_id_seq to authenticated;
