-- Bundle deal prices are final and cannot be combined with any promo source.
--
-- Patch the current secure checkout definition in place so this migration
-- remains layered on top of the bundle-aware checkout function without
-- duplicating that security-critical function's full body.

do $migration$
declare
  v_definition text;
  v_declaration_marker constant text :=
    '  v_requested_code text := upper(trim(coalesce(p_promo_code, '''')));';
  v_cart_marker constant text :=
    E'  if not exists (\n' ||
    E'    select 1 from public.cart where "userID" = v_user_id\n' ||
    E'  ) then\n' ||
    E'    raise exception ''Cart is empty'';\n' ||
    E'  end if;';
  v_manual_promo_marker constant text :=
    E'  if v_requested_code <> '''' then\n' ||
    E'    select * into v_code';
  v_attribution_marker constant text :=
    E'  else\n' ||
    E'    select\n' ||
    E'      a.id as attribution_id,';
begin
  select pg_get_functiondef(
    'public.place_order_secure(text,bigint,text,text,text,text)'::regprocedure
  )
  into v_definition;

  if v_definition is null then
    raise exception 'place_order_secure is not installed';
  end if;

  if position('v_has_bundle boolean' in v_definition) > 0 then
    return;
  end if;

  if position(v_declaration_marker in v_definition) = 0
    or position(v_cart_marker in v_definition) = 0
    or position(v_manual_promo_marker in v_definition) = 0
    or position(v_attribution_marker in v_definition) = 0 then
    raise exception
      'Unexpected place_order_secure definition; bundle promo guard not applied';
  end if;

  v_definition := replace(
    v_definition,
    v_declaration_marker,
    v_declaration_marker || E'\n  v_has_bundle boolean := false;'
  );

  v_definition := replace(
    v_definition,
    v_cart_marker,
    v_cart_marker ||
      E'\n\n  select exists (\n' ||
      E'    select 1\n' ||
      E'    from public.cart\n' ||
      E'    where "userID" = v_user_id\n' ||
      E'      and "bundleID" is not null\n' ||
      E'  ) into v_has_bundle;\n\n' ||
      E'  if v_has_bundle and v_requested_code <> '''' then\n' ||
      E'    raise exception ''Promo codes cannot be used with bundle deals'';\n' ||
      E'  end if;'
  );

  v_definition := replace(
    v_definition,
    v_manual_promo_marker,
    E'  if not v_has_bundle and v_requested_code <> '''' then\n' ||
      E'    select * into v_code'
  );

  -- Saved affiliate attribution is also a promo source. Keep it active for a
  -- later regular order, but do not apply or consume it on a bundle order.
  v_definition := replace(
    v_definition,
    v_attribution_marker,
    E'  elsif not v_has_bundle then\n' ||
      E'    select\n' ||
      E'      a.id as attribution_id,'
  );

  execute v_definition;
end;
$migration$;
