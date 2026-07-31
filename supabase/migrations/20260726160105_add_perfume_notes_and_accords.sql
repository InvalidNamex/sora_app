alter table public.items
  add column if not exists notes text[] not null default '{}'::text[],
  add column if not exists "notesEN" text[] not null default '{}'::text[],
  add column if not exists accords text[] not null default '{}'::text[],
  add column if not exists "accordsEN" text[] not null default '{}'::text[];

comment on column public.items.notes is
  'Ordered Arabic perfume note names. Empty when notes are unavailable.';
comment on column public.items."notesEN" is
  'Ordered English perfume note names. Empty when notes are unavailable.';
comment on column public.items.accords is
  'Ordered Arabic perfume accord names. Empty when accords are unavailable.';
comment on column public.items."accordsEN" is
  'Ordered English perfume accord names. Empty when accords are unavailable.';
