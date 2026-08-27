create extension if not exists pg_trgm with schema extensions;

create table public.vera_config (
  singleton boolean primary key default true check (singleton),
  enabled boolean not null default true,
  hourly_user_limit integer not null default 10 check (hourly_user_limit > 0),
  daily_user_limit integer not null default 30 check (daily_user_limit > 0),
  global_daily_message_limit integer not null default 10000
    check (global_daily_message_limit > 0),
  global_daily_cost_limit_usd numeric(12, 4) not null default 20
    check (global_daily_cost_limit_usd > 0),
  cooldown_seconds integer not null default 5 check (cooldown_seconds >= 0),
  request_lease_seconds integer not null default 60
    check (request_lease_seconds between 10 and 150),
  max_message_characters integer not null default 500
    check (max_message_characters between 100 and 2000),
  max_context_characters integer not null default 3000
    check (max_context_characters between 500 and 12000),
  max_conversation_turns integer not null default 12
    check (max_conversation_turns between 1 and 50),
  max_output_tokens integer not null default 500
    check (max_output_tokens between 100 and 2000),
  recommendation_limit integer not null default 5
    check (recommendation_limit between 1 and 10),
  updated_at timestamptz not null default now()
);

insert into public.vera_config (singleton)
values (true)
on conflict (singleton) do nothing;

comment on table public.vera_config is
  'Server-enforced Vera quotas and global spend controls. Contains one row.';

create table public.perfume_reference_profiles (
  id bigserial primary key,
  source text not null,
  source_record_id text,
  canonical_name text not null,
  brand_name text not null default '',
  concentration text not null default '',
  release_year smallint,
  aliases text[] not null default '{}'::text[],
  top_notes_en text[] not null default '{}'::text[],
  top_notes_ar text[] not null default '{}'::text[],
  middle_notes_en text[] not null default '{}'::text[],
  middle_notes_ar text[] not null default '{}'::text[],
  base_notes_en text[] not null default '{}'::text[],
  base_notes_ar text[] not null default '{}'::text[],
  accords_en text[] not null default '{}'::text[],
  accords_ar text[] not null default '{}'::text[],
  accord_percentages smallint[] not null default '{}'::smallint[],
  source_url text,
  source_evidence jsonb not null default '[]'::jsonb,
  source_confidence numeric(4, 3) not null default 1
    check (source_confidence between 0 and 1),
  fetched_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  search_text text generated always as (
    lower(trim(brand_name || ' ' || canonical_name || ' ' || concentration))
  ) stored,
  constraint perfume_reference_name_not_empty
    check (length(trim(canonical_name)) between 1 and 200),
  constraint perfume_reference_brand_length
    check (length(brand_name) <= 200),
  constraint perfume_reference_concentration_length
    check (length(concentration) <= 80),
  constraint perfume_reference_release_year
    check (release_year is null or release_year between 1700 and 2200),
  constraint perfume_reference_accord_lengths
    check (
      cardinality(accords_en) = cardinality(accord_percentages)
      and (
        cardinality(accords_ar) = 0
        or cardinality(accords_ar) = cardinality(accords_en)
      )
    ),
  constraint perfume_reference_accord_range
    check (
      cardinality(accord_percentages) = 0
      or (
        0 <= all (accord_percentages)
        and 100 >= all (accord_percentages)
      )
    ),
  unique (source, source_record_id)
);

create index perfume_reference_search_trgm_idx
  on public.perfume_reference_profiles
  using gin (search_text extensions.gin_trgm_ops);

create index perfume_reference_fetched_idx
  on public.perfume_reference_profiles (fetched_at desc);

comment on table public.perfume_reference_profiles is
  'Licensed or curated external fragrance profiles used by Vera. No user chat content.';

create table public.vera_usage_daily (
  user_id bigint not null references public.users(id) on delete cascade,
  usage_date date not null,
  request_count integer not null default 0 check (request_count >= 0),
  rejected_count integer not null default 0 check (rejected_count >= 0),
  input_tokens bigint not null default 0 check (input_tokens >= 0),
  output_tokens bigint not null default 0 check (output_tokens >= 0),
  estimated_cost_usd numeric(12, 6) not null default 0
    check (estimated_cost_usd >= 0),
  updated_at timestamptz not null default now(),
  primary key (user_id, usage_date)
);

create index vera_usage_daily_date_idx
  on public.vera_usage_daily (usage_date);

create table public.vera_usage_hourly (
  user_id bigint not null references public.users(id) on delete cascade,
  bucket_start timestamptz not null,
  request_count integer not null default 0 check (request_count >= 0),
  updated_at timestamptz not null default now(),
  primary key (user_id, bucket_start)
);

create table public.vera_request_leases (
  user_id bigint primary key references public.users(id) on delete cascade,
  last_request_at timestamptz,
  active_request_id uuid,
  active_until timestamptz,
  updated_at timestamptz not null default now()
);

alter table public.vera_config enable row level security;
alter table public.perfume_reference_profiles enable row level security;
alter table public.vera_usage_daily enable row level security;
alter table public.vera_usage_hourly enable row level security;
alter table public.vera_request_leases enable row level security;

revoke all on public.vera_config from anon, authenticated;
revoke all on public.perfume_reference_profiles from anon, authenticated;
revoke all on public.vera_usage_daily from anon, authenticated;
revoke all on public.vera_usage_hourly from anon, authenticated;
revoke all on public.vera_request_leases from anon, authenticated;
revoke all on sequence public.perfume_reference_profiles_id_seq
  from anon, authenticated;

create or replace function public.consume_vera_quota(
  p_user_id bigint,
  p_request_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $function$
declare
  v_config public.vera_config%rowtype;
  v_lease public.vera_request_leases%rowtype;
  v_now timestamptz := clock_timestamp();
  v_today date := (v_now at time zone 'UTC')::date;
  v_hour timestamptz := date_trunc('hour', v_now);
  v_daily_count integer := 0;
  v_hourly_count integer := 0;
  v_global_count bigint := 0;
  v_global_cost numeric(12, 6) := 0;
  v_retry integer := 0;
begin
  if p_user_id is null or p_request_id is null then
    return jsonb_build_object('allowed', false, 'reason', 'invalid_request');
  end if;

  if not exists (select 1 from public.users where id = p_user_id) then
    return jsonb_build_object('allowed', false, 'reason', 'unauthorized');
  end if;

  select * into v_config
  from public.vera_config
  where singleton = true
  for update;

  if not found or not v_config.enabled then
    return jsonb_build_object('allowed', false, 'reason', 'disabled');
  end if;

  insert into public.vera_request_leases (user_id)
  values (p_user_id)
  on conflict (user_id) do nothing;

  select * into v_lease
  from public.vera_request_leases
  where user_id = p_user_id
  for update;

  if v_lease.active_until is not null and v_lease.active_until > v_now then
    v_retry := greatest(1, ceil(extract(epoch from v_lease.active_until - v_now))::integer);
    return jsonb_build_object(
      'allowed', false,
      'reason', 'request_in_progress',
      'retry_after_seconds', v_retry
    );
  end if;

  if v_lease.last_request_at is not null
     and v_lease.last_request_at + make_interval(secs => v_config.cooldown_seconds) > v_now then
    v_retry := greatest(
      1,
      ceil(extract(epoch from (
        v_lease.last_request_at
        + make_interval(secs => v_config.cooldown_seconds)
        - v_now
      )))::integer
    );
    return jsonb_build_object(
      'allowed', false,
      'reason', 'cooldown',
      'retry_after_seconds', v_retry
    );
  end if;

  select request_count into v_daily_count
  from public.vera_usage_daily
  where user_id = p_user_id and usage_date = v_today;
  v_daily_count := coalesce(v_daily_count, 0);

  if v_daily_count >= v_config.daily_user_limit then
    return jsonb_build_object('allowed', false, 'reason', 'daily_limit');
  end if;

  select request_count into v_hourly_count
  from public.vera_usage_hourly
  where user_id = p_user_id and bucket_start = v_hour;
  v_hourly_count := coalesce(v_hourly_count, 0);

  if v_hourly_count >= v_config.hourly_user_limit then
    return jsonb_build_object('allowed', false, 'reason', 'hourly_limit');
  end if;

  select coalesce(sum(request_count), 0), coalesce(sum(estimated_cost_usd), 0)
  into v_global_count, v_global_cost
  from public.vera_usage_daily
  where usage_date = v_today;

  if v_global_count >= v_config.global_daily_message_limit
     or v_global_cost >= v_config.global_daily_cost_limit_usd then
    return jsonb_build_object('allowed', false, 'reason', 'global_limit');
  end if;

  insert into public.vera_usage_daily (
    user_id,
    usage_date,
    request_count,
    updated_at
  ) values (
    p_user_id,
    v_today,
    1,
    v_now
  )
  on conflict (user_id, usage_date) do update
  set request_count = public.vera_usage_daily.request_count + 1,
      updated_at = excluded.updated_at;

  insert into public.vera_usage_hourly (
    user_id,
    bucket_start,
    request_count,
    updated_at
  ) values (
    p_user_id,
    v_hour,
    1,
    v_now
  )
  on conflict (user_id, bucket_start) do update
  set request_count = public.vera_usage_hourly.request_count + 1,
      updated_at = excluded.updated_at;

  update public.vera_request_leases
  set last_request_at = v_now,
      active_request_id = p_request_id,
      active_until = v_now + make_interval(secs => v_config.request_lease_seconds),
      updated_at = v_now
  where user_id = p_user_id;

  return jsonb_build_object(
    'allowed', true,
    'hourly_remaining', v_config.hourly_user_limit - v_hourly_count - 1,
    'daily_remaining', v_config.daily_user_limit - v_daily_count - 1,
    'max_message_characters', v_config.max_message_characters,
    'max_context_characters', v_config.max_context_characters,
    'max_conversation_turns', v_config.max_conversation_turns,
    'max_output_tokens', v_config.max_output_tokens,
    'recommendation_limit', v_config.recommendation_limit
  );
end
$function$;

create or replace function public.finish_vera_request(
  p_user_id bigint,
  p_request_id uuid,
  p_input_tokens bigint default 0,
  p_output_tokens bigint default 0,
  p_estimated_cost_usd numeric default 0
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $function$
declare
  v_today date := (clock_timestamp() at time zone 'UTC')::date;
begin
  update public.vera_usage_daily
  set input_tokens = input_tokens + greatest(coalesce(p_input_tokens, 0), 0),
      output_tokens = output_tokens + greatest(coalesce(p_output_tokens, 0), 0),
      estimated_cost_usd = estimated_cost_usd
        + greatest(coalesce(p_estimated_cost_usd, 0), 0),
      updated_at = clock_timestamp()
  where user_id = p_user_id and usage_date = v_today;

  update public.vera_request_leases
  set active_request_id = null,
      active_until = null,
      updated_at = clock_timestamp()
  where user_id = p_user_id and active_request_id = p_request_id;
end
$function$;

create or replace function public.find_vera_reference(
  p_name text,
  p_brand text default '',
  p_limit integer default 5
)
returns setof public.perfume_reference_profiles
language sql
stable
security definer
set search_path = public, extensions, pg_temp
as $function$
  select profile.*
  from public.perfume_reference_profiles as profile
  where similarity(
    profile.search_text,
    lower(trim(coalesce(p_brand, '') || ' ' || coalesce(p_name, '')))
  ) >= 0.4
  order by similarity(
    profile.search_text,
    lower(trim(coalesce(p_brand, '') || ' ' || coalesce(p_name, '')))
  ) desc,
  profile.source_confidence desc,
  profile.updated_at desc
  limit least(greatest(coalesce(p_limit, 5), 1), 20)
$function$;

create or replace function public.cleanup_vera_operational_data(
  p_hourly_retention interval default interval '48 hours',
  p_daily_retention interval default interval '400 days'
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $function$
declare
  v_hourly_deleted integer := 0;
  v_daily_deleted integer := 0;
begin
  delete from public.vera_usage_hourly
  where bucket_start < clock_timestamp() - p_hourly_retention;
  get diagnostics v_hourly_deleted = row_count;

  delete from public.vera_usage_daily
  where usage_date < ((clock_timestamp() - p_daily_retention) at time zone 'UTC')::date;
  get diagnostics v_daily_deleted = row_count;

  update public.vera_request_leases
  set active_request_id = null,
      active_until = null,
      updated_at = clock_timestamp()
  where active_until < clock_timestamp();

  return jsonb_build_object(
    'hourly_deleted', v_hourly_deleted,
    'daily_deleted', v_daily_deleted
  );
end
$function$;

revoke all on function public.consume_vera_quota(bigint, uuid)
  from public, anon, authenticated;
revoke all on function public.finish_vera_request(bigint, uuid, bigint, bigint, numeric)
  from public, anon, authenticated;
revoke all on function public.find_vera_reference(text, text, integer)
  from public, anon, authenticated;
revoke all on function public.cleanup_vera_operational_data(interval, interval)
  from public, anon, authenticated;

grant execute on function public.consume_vera_quota(bigint, uuid)
  to service_role;
grant execute on function public.finish_vera_request(bigint, uuid, bigint, bigint, numeric)
  to service_role;
grant execute on function public.find_vera_reference(text, text, integer)
  to service_role;
grant execute on function public.cleanup_vera_operational_data(interval, interval)
  to service_role;
