create table if not exists public.app_content_versions (
  content_key text primary key,
  version bigint not null default 1 check (version > 0),
  updated_at timestamptz not null default now()
);

insert into public.app_content_versions (content_key, version)
values ('home', 1), ('home_media', 1)
on conflict (content_key) do nothing;

alter table public.app_content_versions enable row level security;

revoke all on public.app_content_versions from anon, authenticated;
grant select on public.app_content_versions to anon, authenticated;

drop policy if exists "Public can read app content versions"
  on public.app_content_versions;
create policy "Public can read app content versions"
on public.app_content_versions
for select
to anon, authenticated
using (true);

create or replace function public.bump_home_content_version()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $function$
begin
  insert into public.app_content_versions (content_key, version, updated_at)
  values ('home', 1, clock_timestamp())
  on conflict (content_key) do update
  set version = public.app_content_versions.version + 1,
      updated_at = excluded.updated_at;
  return null;
end
$function$;

revoke all on function public.bump_home_content_version() from public;

create or replace function public.bump_home_media_version()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $function$
begin
  insert into public.app_content_versions (content_key, version, updated_at)
  values ('home_media', 1, clock_timestamp())
  on conflict (content_key) do update
  set version = public.app_content_versions.version + 1,
      updated_at = excluded.updated_at;
  return null;
end
$function$;

revoke all on function public.bump_home_media_version() from public;

do $migration$
declare
  table_name text;
  trigger_name text;
begin
  foreach table_name in array array[
    'banners',
    'promotions',
    'bundle_deals',
    'bundle_deal_items',
    'categories',
    'sub_categories',
    'items',
    'item_properties',
    'video_ads'
  ] loop
    if to_regclass('public.' || table_name) is null then
      continue;
    end if;

    trigger_name := 'bump_home_content_version_on_' || table_name;
    execute format('drop trigger if exists %I on public.%I', trigger_name, table_name);
    execute format(
      'create trigger %I after insert or update or delete or truncate on public.%I '
      || 'for each statement execute function public.bump_home_content_version()',
      trigger_name,
      table_name
    );
  end loop;
end
$migration$;

do $media_triggers$
declare
  v_table_name text;
  v_column_name text;
  insert_delete_trigger text;
  update_trigger text;
begin
  for v_table_name, v_column_name in
    select * from (values
      ('banners', 'bannerImage'),
      ('banners', 'image'),
      ('bundle_deals', 'bannerImage'),
      ('categories', 'categoryImage'),
      ('categories', 'image'),
      ('sub_categories', 'subCategoryImage'),
      ('sub_categories', 'image'),
      ('item_properties', 'image'),
      ('video_ads', 'videoURL')
    ) as media_tables(table_name, column_name)
  loop
    if to_regclass('public.' || v_table_name) is null then
      continue;
    end if;
    if not exists (
      select 1
      from information_schema.columns
      where table_schema = 'public'
        and table_name = v_table_name
        and column_name = v_column_name
    ) then
      continue;
    end if;

    insert_delete_trigger := 'bump_home_media_version_on_' || v_table_name;
    update_trigger := 'bump_home_media_version_on_' || v_table_name || '_'
      || lower(v_column_name) || '_update';
    execute format(
      'drop trigger if exists %I on public.%I',
      insert_delete_trigger,
      v_table_name
    );
    execute format(
      'drop trigger if exists %I on public.%I',
      update_trigger,
      v_table_name
    );
    execute format(
      'create trigger %I after insert or delete or truncate on public.%I '
      || 'for each statement execute function public.bump_home_media_version()',
      insert_delete_trigger,
      v_table_name
    );
    execute format(
      'create trigger %I after update of %I on public.%I '
      || 'for each statement execute function public.bump_home_media_version()',
      update_trigger,
      v_column_name,
      v_table_name
    );
  end loop;
end
$media_triggers$;

do $realtime$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
     and not exists (
       select 1
       from pg_publication_tables
       where pubname = 'supabase_realtime'
         and schemaname = 'public'
         and tablename = 'app_content_versions'
     ) then
    alter publication supabase_realtime add table public.app_content_versions;
  end if;
end
$realtime$;

comment on table public.app_content_versions is
  'Small public cache validators. Values contain no catalog or user data.';
comment on function public.bump_home_content_version() is
  'Invalidates cached home data after catalog or promotion writes.';
comment on function public.bump_home_media_version() is
  'Rotates media cache keys only when an image or video reference changes.';
