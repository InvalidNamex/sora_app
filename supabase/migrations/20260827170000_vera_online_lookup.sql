alter table public.vera_config
  add column global_daily_lookup_limit integer not null default 30
    check (global_daily_lookup_limit > 0),
  add column reference_cache_days integer not null default 180
    check (reference_cache_days between 1 and 3650);

alter table public.vera_usage_daily
  add column lookup_count integer not null default 0
    check (lookup_count >= 0);

update public.vera_config
set request_lease_seconds = greatest(request_lease_seconds, 90),
    updated_at = now()
where singleton = true;

comment on column public.vera_usage_daily.lookup_count is
  'Count of metered on-demand fragrance web lookups. Contains no query text.';

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
  with query as (
    select lower(trim(coalesce(p_brand, '') || ' ' || coalesce(p_name, ''))) as value
  )
  select profile.*
  from public.perfume_reference_profiles as profile
  cross join query
  where greatest(
    similarity(profile.search_text, query.value),
    similarity(lower(array_to_string(profile.aliases, ' ')), query.value)
  ) >= 0.4
  order by greatest(
    similarity(profile.search_text, query.value),
    similarity(lower(array_to_string(profile.aliases, ' ')), query.value)
  ) desc,
  profile.source_confidence desc,
  profile.updated_at desc
  limit least(greatest(coalesce(p_limit, 5), 1), 20)
$function$;

create or replace function public.consume_vera_lookup_quota(
  p_user_id bigint
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $function$
declare
  v_config public.vera_config%rowtype;
  v_today date := (clock_timestamp() at time zone 'UTC')::date;
  v_global_count bigint := 0;
begin
  if p_user_id is null then
    return jsonb_build_object('allowed', false, 'reason', 'invalid_request');
  end if;

  select * into v_config
  from public.vera_config
  where singleton = true
  for update;

  if not found or not v_config.enabled then
    return jsonb_build_object('allowed', false, 'reason', 'disabled');
  end if;

  select coalesce(sum(lookup_count), 0)
  into v_global_count
  from public.vera_usage_daily
  where usage_date = v_today;

  if v_global_count >= v_config.global_daily_lookup_limit then
    return jsonb_build_object('allowed', false, 'reason', 'lookup_limit');
  end if;

  update public.vera_usage_daily
  set lookup_count = lookup_count + 1,
      updated_at = clock_timestamp()
  where user_id = p_user_id and usage_date = v_today;

  if not found then
    return jsonb_build_object('allowed', false, 'reason', 'request_not_metered');
  end if;

  return jsonb_build_object(
    'allowed', true,
    'remaining', v_config.global_daily_lookup_limit - v_global_count - 1
  );
end
$function$;

revoke all on function public.consume_vera_lookup_quota(bigint)
  from public, anon, authenticated;
grant execute on function public.consume_vera_lookup_quota(bigint)
  to service_role;
