drop function if exists public.admin_reorder_home_sections(bigint[]);

create function public.admin_reorder_home_sections(
  p_section_ids bigint[]
)
returns table(section_id bigint, persisted_order integer)
language plpgsql
security definer
set search_path = public, pg_temp
as $function$
declare
  updated_count integer;
begin
  if not exists (
    select 1
    from public.users
    where uid = (select auth.jwt() ->> 'sub')
      and "isAdmin" = true
  ) then
    raise exception 'Administrator access is required';
  end if;

  if coalesce(cardinality(p_section_ids), 0) <> (
    select count(*) from public.home_sections
  ) or (
    select count(distinct requested_id)
    from unnest(coalesce(p_section_ids, '{}'::bigint[])) as requested(requested_id)
  ) <> coalesce(cardinality(p_section_ids), 0) then
    raise exception 'The requested section order is invalid';
  end if;

  return query
  with requested_order as (
    select requested_id, ordinal::integer - 1 as new_order
    from unnest(p_section_ids)
      with ordinality as requested(requested_id, ordinal)
  )
  update public.home_sections as section
  set display_order = requested_order.new_order
  from requested_order
  where section.id = requested_order.requested_id
  returning section.id, section.display_order;

  get diagnostics updated_count = row_count;
  if updated_count <> cardinality(p_section_ids) then
    raise exception 'Only % of % home sections were reordered',
      updated_count, cardinality(p_section_ids);
  end if;
end
$function$;

revoke all on function public.admin_reorder_home_sections(bigint[]) from public;
grant execute on function public.admin_reorder_home_sections(bigint[]) to authenticated;

notify pgrst, 'reload schema';
