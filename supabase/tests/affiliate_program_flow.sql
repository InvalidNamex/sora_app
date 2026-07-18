insert into public.items ("itemName") values ('Test Item');
insert into public.item_properties ("itemID", price, "inStock")
values (1, 1000, true);
insert into public.address_book ("userID", address, landmark)
values (2, 'Test Address', 'Test Landmark');
insert into public.cart ("userID", "propertyID", quantity)
values (2, 1, 1);

select public.save_affiliate_attribution(
  'customer-firebase-uid',
  'SORA1',
  'link',
  1
);

select public.place_order_secure(
  'customer-firebase-uid',
  1,
  '01000000002',
  '',
  'SORA1',
  'link'
);

do $$
declare
  v_order public.order_master%rowtype;
  v_commission public.affiliate_commissions%rowtype;
begin
  select * into v_order from public.order_master where id = 1;
  if v_order."totalPrice" <> 900
    or v_order."totalDiscount" <> 100
    or v_order."affiliateCommissionAmount" <> 135 then
    raise exception 'Unexpected order totals: %', row_to_json(v_order);
  end if;

  select * into v_commission
  from public.affiliate_commissions
  where "orderID" = 1;
  if v_commission.amount <> 135 or v_commission.status <> 'pending' then
    raise exception 'Unexpected commission: %', row_to_json(v_commission);
  end if;
end;
$$;

update public.order_master
set "orderStatus" = 'Delivered'
where id = 1;

select public.request_affiliate_payout(
  'affiliate-firebase-uid',
  'mobile_wallet',
  '01000000001'
);

select public.review_affiliate_payout(
  'admin-firebase-uid',
  1,
  'paid',
  'TRANSFER-001',
  ''
);

do $$
begin
  if not exists (
    select 1
    from public.affiliate_commissions
    where "orderID" = 1
      and amount = 135
      and status = 'paid'
  ) then
    raise exception 'Commission did not reach paid state';
  end if;
end;
$$;

select public.submit_affiliate_application(
  'applicant-firebase-uid',
  'APPLY26',
  'I create fashion content and want to promote Sora.'
);

select public.review_affiliate_application(
  'admin-firebase-uid',
  1,
  'approve',
  ''
);

do $$
begin
  if not exists (
    select 1
    from public.users u
    join public.affiliate_codes c on c."affiliateID" = u.id
    where u.uid = 'applicant-firebase-uid'
      and u."isAffiliate" = true
      and c.code = 'APPLY26'
      and c."isActive" = true
  ) then
    raise exception 'Affiliate application approval did not provision code';
  end if;

  if not exists (
    select 1 from public.notification_jobs
    where "eventType" = 'admin_order_placed'
  ) then
    raise exception 'New order admin notification was not queued';
  end if;
end;
$$;
