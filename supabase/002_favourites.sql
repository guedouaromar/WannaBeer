-- WannaBeer — favourites (run once in Supabase → SQL Editor, after schema.sql)

-- Each browser gets a random device id so favourites follow the person without a login.
alter table public.participants add column if not exists device_id uuid;

create table if not exists public.favourites (
  id         uuid primary key default gen_random_uuid(),
  owner_id   uuid not null,          -- device id
  owner_name text not null,
  bar_key    text not null,          -- osm id ("node123") or "g:lat,lng" for imports
  name       text not null,
  lat        double precision not null,
  lng        double precision not null,
  source     text not null default 'app',  -- 'app' (starred in the app) | 'import' (Google Takeout)
  created_at timestamptz not null default now(),
  unique (owner_id, bar_key)
);
create index if not exists favourites_owner_idx on public.favourites(owner_id);

alter table public.favourites enable row level security;
drop policy if exists "anon can add favourites" on public.favourites;
create policy "anon can add favourites"    on public.favourites for insert to anon with check (char_length(name) <= 80);
drop policy if exists "anon can read favourites" on public.favourites;
create policy "anon can read favourites"   on public.favourites for select to anon using (true);
drop policy if exists "anon can remove favourites" on public.favourites;
create policy "anon can remove favourites" on public.favourites for delete to anon using (true);
