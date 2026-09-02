create or replace function public.admin_reorder_home_sections(
  p_section_ids bigint[]
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $function$
begin
  if not exists (
    select 1
    from public.users
    where uid = (select auth.jwt() ->> 'sub')
      and "isAdmin" = true
  ) then
    raise exception 'Administrator access is required';
  end if;

  with requested_order as (
    select section_id, ordinal - 1 as display_order
    from unnest(coalesce(p_section_ids, '{}'::bigint[]))
      with ordinality as requested(section_id, ordinal)
  )
  update public.home_sections as section
  set display_order = requested_order.display_order
  from requested_order
  where section.id = requested_order.section_id;
end
$function$;
