-- Sora in-app campaigns. Admin writes go through the authenticated
-- manage-in-app-messages Edge Function; clients may only read live campaigns.

create table if not exists public.in_app_messages (
  id bigserial primary key,
  type text not null check (type in ('card', 'modal', 'image', 'banner')),
  title text not null default '',
  body text not null default '',
  image_url text not null default '',
  background_color text not null default '#FFFFFF',
  text_color text not null default '#171717',
  button_color text not null default '#B09263',
  button_text_color text not null default '#FFFFFF',
  primary_button_text text not null default '',
  primary_action_url text not null default '',
  secondary_button_text text not null default '',
  secondary_action_url text not null default '',
  target_platform text not null default 'all'
    check (target_platform in ('all', 'android', 'ios', 'web')),
  target_language text not null default 'all'
    check (target_language in ('all', 'en', 'ar')),
  display_once boolean not null default true,
  is_active boolean not null default true,
  priority integer not null default 0,
  starts_at timestamptz not null default now(),
  ends_at timestamptz,
  created_by text,
  created_at timestamptz not null default now(),
  constraint in_app_message_dates check (
    ends_at is null or ends_at > starts_at
  )
);

create index if not exists idx_in_app_messages_live
  on public.in_app_messages(is_active, starts_at, ends_at);

alter table public.in_app_messages enable row level security;

drop policy if exists "Read live in-app campaigns"
  on public.in_app_messages;
create policy "Read live in-app campaigns"
  on public.in_app_messages
  for select
  to anon, authenticated
  using (
    is_active = true
    and starts_at <= now()
    and (ends_at is null or ends_at > now())
  );

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'in_app_messages'
  ) then
    alter publication supabase_realtime
      add table public.in_app_messages;
  end if;
end
$$;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'in_app_messages',
  'in_app_messages',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;
