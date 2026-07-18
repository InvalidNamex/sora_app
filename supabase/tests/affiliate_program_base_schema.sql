create schema if not exists public;

create table public.users (
  id bigserial primary key,
  uid text not null unique,
  name text not null default '',
  phone text not null default '',
  "isAffiliate" boolean not null default false,
  "isAdmin" boolean not null default false
);

create table public.items (
  id bigserial primary key,
  "itemName" text not null,
  "isFeatured" boolean not null default false
);

create table public.item_properties (
  id bigserial primary key,
  "itemID" bigint not null references public.items(id),
  price double precision not null,
  "inStock" boolean not null default true,
  "affiliatePercentage" double precision
);

create table public.address_book (
  id bigserial primary key,
  "userID" bigint not null references public.users(id),
  address text not null,
  landmark text
);

create table public.cart (
  id bigserial primary key,
  "userID" bigint not null references public.users(id),
  "propertyID" bigint not null references public.item_properties(id),
  quantity integer not null
);

create table public.order_master (
  id bigserial primary key,
  "userID" bigint not null references public.users(id),
  "addressID" bigint not null references public.address_book(id),
  "affiliateID" bigint references public.users(id),
  address text,
  "phoneNumber" text,
  "totalPrice" double precision not null,
  "totalDiscount" double precision not null default 0,
  notes text,
  "orderStatus" text not null default 'Pending',
  created_at timestamptz not null default now()
);

create table public.order_detail (
  id bigserial primary key,
  "orderMasterID" bigint not null references public.order_master(id),
  "itemPropertyID" bigint not null references public.item_properties(id),
  "itemName" text not null,
  quantity integer not null,
  price double precision not null
);

create table public.vouchers (
  id bigserial primary key,
  "voucherCode" text not null unique,
  "voucherAmount" double precision,
  "voucherPercentage" double precision,
  "isActive" boolean not null default true
);

create table public.promotions (
  id bigserial primary key,
  "promotionCode" text not null unique,
  "promotionDiscount" double precision not null,
  "expiry_date" timestamptz
);

create table public.payout_requests (
  id bigserial primary key,
  "affiliateID" bigint not null references public.users(id),
  amount double precision not null,
  status text not null default 'Pending',
  created_at timestamptz not null default now()
);

create table public.notification_jobs (
  id bigserial primary key,
  "eventType" text not null,
  title text not null,
  body text not null,
  payload jsonb not null default '{}'::jsonb,
  "isAndroidOnly" boolean not null default false,
  "isArabicOnly" boolean not null default false,
  status text not null default 'pending',
  attempts integer not null default 0,
  "lastError" text,
  "lockedAt" timestamptz,
  "createdAt" timestamptz not null default now(),
  "processedAt" timestamptz
);

do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then
    create role anon;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then
    create role authenticated;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'service_role') then
    create role service_role;
  end if;
end;
$$;

insert into public.users (uid, name, phone, "isAffiliate", "isAdmin")
values
  ('affiliate-firebase-uid', 'Affiliate', '01000000001', true, false),
  ('customer-firebase-uid', 'Customer', '01000000002', false, false),
  ('admin-firebase-uid', 'Admin', '01000000003', false, true),
  ('applicant-firebase-uid', 'Applicant', '01000000004', false, false);
