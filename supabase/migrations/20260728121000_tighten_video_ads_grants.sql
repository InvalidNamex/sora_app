revoke all on public.video_ads from anon, authenticated;
revoke all on sequence public.video_ads_id_seq from anon, authenticated;

grant select on public.video_ads to anon, authenticated;
grant insert, update, delete on public.video_ads to authenticated;
grant usage, select on sequence public.video_ads_id_seq to authenticated;
