alter table public.video_ads
  alter column "videoURL" drop not null;

alter table public.video_ads
  add column if not exists "bannerURL" text;

alter table public.video_ads
  drop constraint if exists video_ads_video_url_not_empty;

alter table public.video_ads
  add constraint video_ads_has_media check (
    length(trim(coalesce("videoURL", ''))) > 0
    or length(trim(coalesce("bannerURL", ''))) > 0
  );

insert into storage.buckets (
  id, name, public, file_size_limit, allowed_mime_types
)
values (
  'ad_banners', 'ad_banners', true, 10485760,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Public can view ad banners" on storage.objects;
create policy "Public can view ad banners"
on storage.objects for select to public
using (bucket_id = 'ad_banners');

drop policy if exists "Admins can upload ad banners" on storage.objects;
create policy "Admins can upload ad banners"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'ad_banners'
  and exists (
    select 1 from public.users
    where users.uid = (select auth.jwt() ->> 'sub')
      and users."isAdmin" = true
  )
);

drop policy if exists "Admins can update ad banners" on storage.objects;
create policy "Admins can update ad banners"
on storage.objects for update to authenticated
using (
  bucket_id = 'ad_banners'
  and exists (
    select 1 from public.users
    where users.uid = (select auth.jwt() ->> 'sub')
      and users."isAdmin" = true
  )
)
with check (
  bucket_id = 'ad_banners'
  and exists (
    select 1 from public.users
    where users.uid = (select auth.jwt() ->> 'sub')
      and users."isAdmin" = true
  )
);

drop policy if exists "Admins can delete ad banners" on storage.objects;
create policy "Admins can delete ad banners"
on storage.objects for delete to authenticated
using (
  bucket_id = 'ad_banners'
  and exists (
    select 1 from public.users
    where users.uid = (select auth.jwt() ->> 'sub')
      and users."isAdmin" = true
  )
);
