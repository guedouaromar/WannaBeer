-- WannaBeer — accounts, friends, invites (run once in Supabase → SQL Editor, after 002)

-- ── profiles: one row per signed-in user, created automatically ──
create table if not exists public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  email        text not null,
  display_name text,
  created_at   timestamptz not null default now()
);
create unique index if not exists profiles_email_idx on public.profiles (lower(email));

create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email, display_name)
  values (new.id, new.email, coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)))
  on conflict (id) do update set email = excluded.email;
  return new;
end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();

-- ── friends: my address book (by email; linked to a profile once they sign up) ──
create table if not exists public.friends (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references auth.users(id) on delete cascade,
  friend_email   text not null,
  friend_name    text,
  friend_user_id uuid references auth.users(id) on delete set null,
  favourite      boolean not null default false,
  beers          int not null default 0,
  last_beer_at   timestamptz,
  created_at     timestamptz not null default now(),
  unique (user_id, friend_email)
);
create index if not exists friends_user_idx on public.friends(user_id);

-- ── invites: "Omar wants a beer" for a specific person ──
create table if not exists public.invites (
  id           uuid primary key default gen_random_uuid(),
  plan_id      uuid not null references public.plans(id) on delete cascade,
  from_user_id uuid not null references auth.users(id) on delete cascade,
  from_name    text not null,
  to_email     text not null,
  to_name      text,
  status       text not null default 'pending',   -- pending | yes | no | seen
  created_at   timestamptz not null default now()
);
create index if not exists invites_to_idx on public.invites (lower(to_email), status);
create index if not exists invites_plan_idx on public.invites (plan_id);

-- ── link plans/participants to accounts (nullable: link-mode guests still work) ──
alter table public.plans        add column if not exists host_user_id uuid references auth.users(id) on delete set null;
alter table public.participants add column if not exists user_id      uuid references auth.users(id) on delete set null;

-- ── RLS ──
alter table public.profiles enable row level security;
alter table public.friends  enable row level security;
alter table public.invites  enable row level security;

-- Existing policies were "to anon" only; signed-in users use the "authenticated" role.
do $$ declare p record; begin
  for p in select policyname, tablename from pg_policies where schemaname='public' and tablename in ('plans','participants','favourites') loop
    execute format('drop policy if exists %I on public.%I', p.policyname, p.tablename);
  end loop;
end $$;
create policy "anyone can create plans"       on public.plans        for insert to anon, authenticated with check (true);
create policy "anyone can read plans"         on public.plans        for select to anon, authenticated using (true);
create policy "anyone can join"               on public.participants for insert to anon, authenticated with check (char_length(name) <= 40);
create policy "anyone can read participants"  on public.participants for select to anon, authenticated using (true);
create policy "anyone can add favourites"     on public.favourites   for insert to anon, authenticated with check (char_length(name) <= 80);
create policy "anyone can read favourites"    on public.favourites   for select to anon, authenticated using (true);
create policy "anyone can remove favourites"  on public.favourites   for delete to anon, authenticated using (true);

-- profiles: signed-in users can look each other up (needed to show friends' names)
create policy "signed-in can read profiles"   on public.profiles for select to authenticated using (true);
create policy "own profile insert"            on public.profiles for insert to authenticated with check (id = auth.uid());
create policy "own profile update"            on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- friends: strictly mine
create policy "own friends select" on public.friends for select to authenticated using (user_id = auth.uid());
create policy "own friends insert" on public.friends for insert to authenticated with check (user_id = auth.uid());
create policy "own friends update" on public.friends for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "own friends delete" on public.friends for delete to authenticated using (user_id = auth.uid());

-- invites: sender can create/see; recipient (matched by email) can see and answer
create policy "send invites"   on public.invites for insert to authenticated with check (from_user_id = auth.uid());
create policy "see my invites" on public.invites for select to authenticated
  using (from_user_id = auth.uid() or lower(to_email) = lower(coalesce(auth.jwt()->>'email','')));
create policy "answer invites" on public.invites for update to authenticated
  using (lower(to_email) = lower(coalesce(auth.jwt()->>'email',''))) with check (lower(to_email) = lower(coalesce(auth.jwt()->>'email','')));

notify pgrst, 'reload schema';
