-- ---------------------------------------------------------------------------
-- Improvy AI — schema iniziale
--
-- Eseguire una volta sola: Supabase Dashboard -> SQL Editor -> incolla ed esegui.
--
-- Nota su RLS (Row Level Security): ogni tabella è chiusa di default. Le policy
-- qui sotto sono l'unico modo per leggere/scrivere, e legano sempre la riga a
-- auth.uid(), cioè all'utente loggato. Senza questo, chiunque avesse la chiave
-- pubblica potrebbe leggere le conversazioni di tutti.
-- ---------------------------------------------------------------------------

-- === profiles ===============================================================
-- Una riga per utente registrato. Estende auth.users (gestita da Supabase).
create table if not exists public.profiles (
  id                    uuid primary key references auth.users (id) on delete cascade,
  email                 text,
  full_name             text,
  avatar_url            text,
  -- dati raccolti nell'onboarding
  onboarding_completed  boolean not null default false,
  role                  text,          -- es. "studente", "sviluppatore", ...
  use_case              text,          -- a cosa gli serve Improvy
  experience_level      text,          -- "principiante" | "intermedio" | "esperto"
  preferred_agent       text not null default 'generale',
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "profiles: leggi il tuo profilo" on public.profiles;
create policy "profiles: leggi il tuo profilo"
  on public.profiles for select
  using (auth.uid() = id);

drop policy if exists "profiles: modifica il tuo profilo" on public.profiles;
create policy "profiles: modifica il tuo profilo"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

drop policy if exists "profiles: crea il tuo profilo" on public.profiles;
create policy "profiles: crea il tuo profilo"
  on public.profiles for insert
  with check (auth.uid() = id);

-- Crea automaticamente il profilo appena l'utente si registra con Google.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name, avatar_url)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name'),
    new.raw_user_meta_data ->> 'avatar_url'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- === conversations ==========================================================
create table if not exists public.conversations (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  title       text not null default 'Nuova conversazione',
  agent_id    text not null default 'generale',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index if not exists conversations_user_updated_idx
  on public.conversations (user_id, updated_at desc);

alter table public.conversations enable row level security;

drop policy if exists "conversations: solo le tue" on public.conversations;
create policy "conversations: solo le tue"
  on public.conversations for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- === messages ===============================================================
create table if not exists public.messages (
  id               uuid primary key default gen_random_uuid(),
  conversation_id  uuid not null references public.conversations (id) on delete cascade,
  user_id          uuid not null references auth.users (id) on delete cascade,
  role             text not null check (role in ('user', 'assistant')),
  content          text not null,
  -- tracciamento costi/debug: quale agente e modello hanno risposto
  agent_id         text,
  model            text,
  input_tokens     integer,
  output_tokens    integer,
  created_at       timestamptz not null default now()
);

create index if not exists messages_conversation_created_idx
  on public.messages (conversation_id, created_at asc);

alter table public.messages enable row level security;

drop policy if exists "messages: solo i tuoi" on public.messages;
create policy "messages: solo i tuoi"
  on public.messages for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- === updated_at automatico ==================================================
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_touch_updated_at on public.profiles;
create trigger profiles_touch_updated_at
  before update on public.profiles
  for each row execute function public.touch_updated_at();

drop trigger if exists conversations_touch_updated_at on public.conversations;
create trigger conversations_touch_updated_at
  before update on public.conversations
  for each row execute function public.touch_updated_at();
