do $media_triggers$
declare
  v_trigger_name text := 'bump_home_media_version_on_video_ads_bannerURL';
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'video_ads'
      and column_name = 'bannerURL'
  ) then
    execute format('drop trigger if exists %I on public.video_ads', v_trigger_name);
    execute format(
      'create trigger %I after insert or update or delete or truncate on public.video_ads '
      || 'for each statement execute function public.bump_home_media_version()',
      v_trigger_name
    );
  end if;
end
$media_triggers$;
