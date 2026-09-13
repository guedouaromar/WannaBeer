-- WannaBeer — run this once in Supabase → SQL Editor
create extension if not exists pgcrypto;

create table if not exists public.plans (
  id         uuid primary key default gen_random_uuid(),
  host_name  text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.participants (
  id         uuid primary key default gen_random_uuid(),
  plan_id    uuid not null references public.plans(id) on delete cascade,
  name       text not null,
  lat        double precision not null,
  lng        double precision not null,
  bike       boolean not null default true,
  created_at timestamptz not null default now()
);
create index if not exists participants_plan_idx on public.participants(plan_id);

-- Anyone with the (unguessable) plan link can read it and add themselves.
alter table public.plans        enable row level security;
alter table public.participants enable row level security;

drop policy if exists "anon can create plans" on public.plans;
create policy "anon can create plans" on public.plans for insert to anon with check (true);
drop policy if exists "anon can read plans" on public.plans;
create policy "anon can read plans"   on public.plans for select to anon using (true);

drop policy if exists "anon can join" on public.participants;
create policy "anon can join"         on public.participants for insert to anon with check (char_length(name) <= 40);
drop policy if exists "anon can read participants" on public.participants;
create policy "anon can read participants" on public.participants for select to anon using (true);

-- Live updates (optional but nice): Database → Replication → enable `participants`,
-- or run:
alter publication supabase_realtime add table public.participants;

-- Housekeeping: auto-delete plans older than 2 days (needs pg_cron, Dashboard → Extensions)
-- select cron.schedule('wannabeer-cleanup', '0 4 * * *', $$delete from public.plans where created_at < now() - interval '2 days'$$);
