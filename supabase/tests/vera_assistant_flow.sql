begin;

do $test$
declare
  v_user_id bigint;
  v_first jsonb;
  v_second jsonb;
  v_lookup_first jsonb;
  v_lookup_second jsonb;
  v_request_id uuid := gen_random_uuid();
begin
  insert into public.users (uid, name, phone)
  values ('vera-test-user', 'Vera Test', '+200000000000')
  returning id into v_user_id;

  update public.vera_config
  set hourly_user_limit = 1,
      daily_user_limit = 2,
      cooldown_seconds = 0,
      global_daily_message_limit = 100,
      global_daily_cost_limit_usd = 100,
      global_daily_lookup_limit = 1
  where singleton = true;

  v_first := public.consume_vera_quota(v_user_id, v_request_id);
  if coalesce((v_first ->> 'allowed')::boolean, false) is not true then
    raise exception 'First Vera request should be allowed: %', v_first;
  end if;

  perform public.finish_vera_request(v_user_id, v_request_id, 100, 20, 0.01);

  v_lookup_first := public.consume_vera_lookup_quota(v_user_id);
  if coalesce((v_lookup_first ->> 'allowed')::boolean, false) is not true then
    raise exception 'First Vera lookup should be allowed: %', v_lookup_first;
  end if;

  v_lookup_second := public.consume_vera_lookup_quota(v_user_id);
  if v_lookup_second ->> 'reason' <> 'lookup_limit' then
    raise exception 'Global lookup limit was not enforced: %', v_lookup_second;
  end if;

  if exists (
    select 1
    from public.vera_request_leases
    where user_id = v_user_id
      and (active_request_id is not null or active_until is not null)
  ) then
    raise exception 'finish_vera_request did not release the lease';
  end if;

  v_second := public.consume_vera_quota(v_user_id, gen_random_uuid());
  if v_second ->> 'reason' <> 'hourly_limit' then
    raise exception 'Hourly limit was not enforced: %', v_second;
  end if;

  if not exists (
    select 1
    from public.vera_usage_daily
    where user_id = v_user_id
      and request_count = 1
      and input_tokens = 100
      and output_tokens = 20
      and estimated_cost_usd = 0.01
      and lookup_count = 1
  ) then
    raise exception 'Vera usage accounting was not recorded correctly';
  end if;
end
$test$;

insert into public.perfume_reference_profiles (
  source,
  source_record_id,
  canonical_name,
  brand_name,
  aliases,
  accords_en,
  accord_percentages
) values (
  'test',
  '1',
  'Test Perfume',
  'Test Brand',
  array['Alternative Test Scent'],
  array['Woody', 'Citrus'],
  array[100, 70]::smallint[]
);

do $test$
begin
  if (
    select count(*)
    from public.find_vera_reference('Test Perfume', 'Test Brand', 5)
  ) <> 1 then
    raise exception 'Vera reference fuzzy lookup failed';
  end if;

  if (
    select count(*)
    from public.find_vera_reference('Alternative Test Scent', '', 5)
  ) <> 1 then
    raise exception 'Vera reference alias lookup failed';
  end if;

  if to_regclass('public.vera_messages') is not null
     or to_regclass('public.vera_conversations') is not null then
    raise exception 'Vera must not persist chat content';
  end if;
end
$test$;

rollback;
