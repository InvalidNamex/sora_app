create table if not exists public.order_feedback (
  id bigserial primary key,
  order_id bigint not null unique
    references public.order_master(id) on delete cascade,
  user_id bigint not null
    references public.users(id) on delete cascade,
  delivery_rating smallint not null,
  delivery_comment text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint order_feedback_delivery_rating_valid
    check (delivery_rating between 1 and 5),
  constraint order_feedback_delivery_comment_length
    check (
      delivery_comment is null or length(delivery_comment) <= 2000
    )
);

create table if not exists public.product_reviews (
  id bigserial primary key,
  order_id bigint not null
    references public.order_master(id) on delete cascade,
  order_detail_id bigint not null unique
    references public.order_detail(id) on delete cascade,
  user_id bigint not null
    references public.users(id) on delete cascade,
  item_property_id bigint
    references public.item_properties(id) on delete set null,
  product_rating smallint not null,
  review_text text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint product_reviews_rating_valid
    check (product_rating between 1 and 5),
  constraint product_reviews_text_length
    check (review_text is null or length(review_text) <= 2000)
);

create index if not exists order_feedback_user_created_idx
  on public.order_feedback (user_id, created_at desc);
create index if not exists product_reviews_order_idx
  on public.product_reviews (order_id);
create index if not exists product_reviews_property_created_idx
  on public.product_reviews (item_property_id, created_at desc);

alter table public.order_feedback enable row level security;
alter table public.product_reviews enable row level security;

drop policy if exists "Customers can view their order feedback"
  on public.order_feedback;
create policy "Customers can view their order feedback"
on public.order_feedback for select to authenticated
using (
  user_id = (
    select id from public.users
    where uid = (select auth.jwt() ->> 'sub')
  )
  or exists (
    select 1 from public.users
    where uid = (select auth.jwt() ->> 'sub')
      and "isAdmin" = true
  )
);

drop policy if exists "Customers can view their product reviews"
  on public.product_reviews;
create policy "Customers can view their product reviews"
on public.product_reviews for select to authenticated
using (
  user_id = (
    select id from public.users
    where uid = (select auth.jwt() ->> 'sub')
  )
  or exists (
    select 1 from public.users
    where uid = (select auth.jwt() ->> 'sub')
      and "isAdmin" = true
  )
);

grant select on public.order_feedback to authenticated;
grant select on public.product_reviews to authenticated;

create or replace function public.submit_order_feedback(
  p_order_id bigint,
  p_delivery_rating integer,
  p_delivery_comment text,
  p_product_reviews jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id bigint;
  v_review jsonb;
  v_detail_id bigint;
  v_property_id bigint;
  v_rating integer;
begin
  select id into v_user_id
  from public.users
  where uid = (select auth.jwt() ->> 'sub')
    and coalesce("isDeleted", false) = false;

  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  if p_delivery_rating not between 1 and 5 then
    raise exception 'Delivery rating must be between 1 and 5';
  end if;

  if jsonb_typeof(coalesce(p_product_reviews, '[]'::jsonb)) <> 'array'
     or jsonb_array_length(coalesce(p_product_reviews, '[]'::jsonb)) = 0 then
    raise exception 'At least one product rating is required';
  end if;

  if not exists (
    select 1
    from public.order_master
    where id = p_order_id
      and "userID" = v_user_id
      and "orderStatus" = 'Delivered'
  ) then
    raise exception 'Only your delivered orders can be reviewed';
  end if;

  if (
    select count(distinct (review ->> 'order_detail_id')::bigint)
    from jsonb_array_elements(p_product_reviews) as submitted(review)
  ) <> (
    select count(*)
    from public.order_detail
    where "orderMasterID" = p_order_id
  ) then
    raise exception 'Every product in the order must be rated exactly once';
  end if;

  insert into public.order_feedback (
    order_id,
    user_id,
    delivery_rating,
    delivery_comment,
    updated_at
  ) values (
    p_order_id,
    v_user_id,
    p_delivery_rating,
    nullif(trim(coalesce(p_delivery_comment, '')), ''),
    now()
  )
  on conflict (order_id) do update set
    delivery_rating = excluded.delivery_rating,
    delivery_comment = excluded.delivery_comment,
    updated_at = now()
  where order_feedback.user_id = v_user_id;

  for v_review in
    select value
    from jsonb_array_elements(p_product_reviews)
  loop
    v_detail_id := (v_review ->> 'order_detail_id')::bigint;
    v_rating := (v_review ->> 'rating')::integer;

    if v_rating not between 1 and 5 then
      raise exception 'Product rating must be between 1 and 5';
    end if;

    select "itemPropertyID" into v_property_id
    from public.order_detail
    where id = v_detail_id
      and "orderMasterID" = p_order_id;

    if not found then
      raise exception 'A reviewed product does not belong to this order';
    end if;

    insert into public.product_reviews (
      order_id,
      order_detail_id,
      user_id,
      item_property_id,
      product_rating,
      review_text,
      updated_at
    ) values (
      p_order_id,
      v_detail_id,
      v_user_id,
      v_property_id,
      v_rating,
      nullif(trim(coalesce(v_review ->> 'review', '')), ''),
      now()
    )
    on conflict (order_detail_id) do update set
      product_rating = excluded.product_rating,
      review_text = excluded.review_text,
      updated_at = now()
    where product_reviews.user_id = v_user_id
      and product_reviews.order_id = p_order_id;
  end loop;
end;
$$;

revoke all on function public.submit_order_feedback(
  bigint, integer, text, jsonb
) from public, anon;
grant execute on function public.submit_order_feedback(
  bigint, integer, text, jsonb
) to authenticated;
