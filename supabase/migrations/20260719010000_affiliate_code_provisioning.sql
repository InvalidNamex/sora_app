-- Keep affiliate code provisioning complete for both imported and updated users.

create or replace function public.ensure_affiliate_code()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new."isAffiliate" = true then
    insert into public.affiliate_codes ("affiliateID", code, "isActive")
    values (new.id, 'SORA' || new.id::text, true)
    on conflict ("affiliateID")
    do update set
      "isActive" = true,
      "updatedAt" = now();
  elsif tg_op = 'UPDATE'
      and old."isAffiliate" = true
      and new."isAffiliate" = false then
    update public.affiliate_codes
    set "isActive" = false, "updatedAt" = now()
    where "affiliateID" = new.id;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_ensure_affiliate_code on public.users;
create trigger trg_ensure_affiliate_code
after insert or update of "isAffiliate" on public.users
for each row
execute function public.ensure_affiliate_code();

insert into public.affiliate_codes ("affiliateID", code, "isActive")
select id, 'SORA' || id::text, true
from public.users
where "isAffiliate" = true
on conflict ("affiliateID")
do update set
  "isActive" = true,
  "updatedAt" = now();
