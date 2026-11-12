-- Krusedull database setup for Supabase.
-- Run this once in the Supabase dashboard: SQL Editor -> New query -> paste -> Run.
-- Players are anonymous (no sign-in), so the policies below let anyone with the
-- project's anon key read and write game data. Only room codes keep games apart.

-- One row per game room. `state` holds the whole game state as JSON.
create table if not exists public.rooms (
  id text primary key check (id ~ '^[a-z0-9-]{3,40}$'),
  state jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

-- People who have joined a room's lobby.
create table if not exists public.players (
  room_id text not null references public.rooms(id) on delete cascade,
  pid text not null check (char_length(pid) between 8 and 40),
  nick text not null default '' check (char_length(nick) <= 24),
  joined_at bigint not null,
  primary key (room_id, pid)
);

-- One row per correct guess. Scores are summed from these rows.
create table if not exists public.hits (
  room_id text not null references public.rooms(id) on delete cascade,
  turn_id text not null,
  pid text not null,
  game_id text not null,
  drawer text,
  pts int not null check (pts between 0 and 600),
  at bigint not null,
  primary key (room_id, turn_id, pid)
);

-- The current drawing, saved every few seconds so late joiners can catch up.
create table if not exists public.canvases (
  room_id text primary key references public.rooms(id) on delete cascade,
  turn_id text,
  strokes jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now()
);

-- Shallow-merges a patch into a room's state in one atomic statement,
-- so two players updating different fields at once don't overwrite each other.
create or replace function public.merge_state(p_room text, p_patch jsonb)
returns void
language sql
security invoker
as $$
  update public.rooms
     set state = state || p_patch, updated_at = now()
   where id = p_room;
$$;

alter table public.rooms enable row level security;
alter table public.players enable row level security;
alter table public.hits enable row level security;
alter table public.canvases enable row level security;

-- Open read/write access for anonymous players.
do $$
declare t text;
begin
  foreach t in array array['rooms', 'players', 'hits', 'canvases'] loop
    execute format('drop policy if exists "krusedull anon access" on public.%I', t);
    execute format(
      'create policy "krusedull anon access" on public.%I for all to anon, authenticated using (true) with check (true)',
      t
    );
  end loop;
end $$;

grant execute on function public.merge_state(text, jsonb) to anon, authenticated;

-- Send row changes to connected browsers in real time.
do $$
declare t text;
begin
  foreach t in array array['rooms', 'players', 'hits', 'canvases'] loop
    if not exists (
      select 1 from pg_publication_tables
       where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;
