-- Client Cue Creative initial multi-business schema.
-- Apply only after confirming this Supabase project is dedicated to this application.
-- Creates new tables only; never drops or alters existing tables.

create extension if not exists pgcrypto;

create table if not exists public.business_units (
  id uuid primary key default gen_random_uuid(),
  code text not null unique check (code in ('001','004','003','005')),
  name text not null,
  market text not null,
  currencies text[] not null,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

insert into public.business_units (code, name, market, currencies) values
  ('001', 'Serviços terapêuticos', 'Portugal', array['EUR']),
  ('004', 'Desconto de eletricidade', 'Brasil', array['BRL']),
  ('003', 'Cursos online', 'Internacional', array['EUR','BRL']),
  ('005', 'GFI HUB', 'Internacional', array['USD','BRL'])
on conflict (code) do nothing;

create table if not exists public.business_memberships (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.business_units(id) on delete restrict,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member' check (role in ('owner','admin','manager','agent','analyst')),
  created_at timestamptz not null default now(),
  unique (business_id, user_id)
);

-- Keep authorization helpers outside exposed API schemas and run with caller privileges.
create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;

create or replace function private.has_business_access(target_business_id uuid)
returns boolean
language sql
stable
security invoker
set search_path = ''
as $
  select exists (
    select 1
    from public.business_memberships as m
    where m.business_id = target_business_id
      and m.user_id = (select auth.uid())
  );
$;
revoke all on function private.has_business_access(uuid) from public, anon;
grant execute on function private.has_business_access(uuid) to authenticated;

create table if not exists public.contacts (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.business_units(id) on delete restrict,
  full_name text,
  email text,
  phone_e164 text,
  country_code text,
  source text,
  source_detail jsonb not null default '{}'::jsonb,
  lifecycle_stage text not null default 'new' check (lifecycle_stage in ('new','qualified','customer','inactive','do_not_contact')),
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (email is not null or phone_e164 is not null),
  unique (id, business_id)
);
create index if not exists contacts_business_created_idx on public.contacts (business_id, created_at desc);
create index if not exists contacts_business_phone_idx on public.contacts (business_id, phone_e164);

create table if not exists public.campaigns (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.business_units(id) on delete restrict,
  name text not null,
  channel text not null check (channel in ('whatsapp','meta','google_ads','instagram','tiktok','linkedin','website','referral','other')),
  external_campaign_id text,
  status text not null default 'draft' check (status in ('draft','active','paused','completed','archived')),
  budget numeric(14,2),
  currency text,
  starts_at timestamptz,
  ends_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, business_id)
);

create table if not exists public.opportunities (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.business_units(id) on delete restrict,
  contact_id uuid not null references public.contacts(id) on delete cascade,
  campaign_id uuid references public.campaigns(id) on delete restrict,
  title text not null,
  stage text not null default 'new' check (stage in ('new','contacted','qualified','proposal','won','lost')),
  amount numeric(14,2),
  currency text,
  expected_close_at timestamptz,
  lost_reason text,
  owner_user_id uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  unique (id, business_id),
  updated_at timestamptz not null default now(),
  foreign key (contact_id, business_id) references public.contacts(id, business_id) on delete cascade,
  foreign key (campaign_id, business_id) references public.campaigns(id, business_id) on delete restrict
);
create index if not exists opportunities_business_stage_idx on public.opportunities (business_id, stage, created_at desc);

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.business_units(id) on delete restrict,
  contact_id uuid not null references public.contacts(id) on delete cascade,
  channel text not null default 'whatsapp',
  external_conversation_id text,
  status text not null default 'open' check (status in ('open','pending','human_handoff','closed')),
  assigned_to uuid references auth.users(id) on delete set null,
  last_message_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, business_id),
  foreign key (contact_id, business_id) references public.contacts(id, business_id) on delete cascade
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.business_units(id) on delete restrict,
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  external_message_id text,
  direction text not null check (direction in ('inbound','outbound')),
  message_type text not null default 'text',
  body text,
  delivery_status text not null default 'received' check (delivery_status in ('received','queued','sent','delivered','read','failed')),
  provider_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (business_id, external_message_id),
  foreign key (conversation_id, business_id) references public.conversations(id, business_id) on delete cascade
);
create index if not exists messages_conversation_created_idx on public.messages (conversation_id, created_at);

create table if not exists public.consents (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.business_units(id) on delete restrict,
  contact_id uuid not null references public.contacts(id) on delete cascade,
  purpose text not null,
  channel text not null,
  status text not null check (status in ('granted','withdrawn','denied')),
  captured_at timestamptz not null default now(),
  source text,
  evidence jsonb not null default '{}'::jsonb,
  foreign key (contact_id, business_id) references public.contacts(id, business_id) on delete cascade
);

create table if not exists public.appointments (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.business_units(id) on delete restrict,
  contact_id uuid not null references public.contacts(id) on delete cascade,
  title text not null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  timezone text not null,
  status text not null default 'scheduled' check (status in ('scheduled','confirmed','cancelled','completed','no_show')),
  calendar_provider text,
  external_event_id text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (ends_at > starts_at),
  foreign key (contact_id, business_id) references public.contacts(id, business_id) on delete cascade
);

create table if not exists public.integration_connections (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.business_units(id) on delete restrict,
  provider text not null check (provider in ('supabase','whatsapp','google_calendar','meta','instagram','tiktok','linkedin')),
  status text not null default 'not_connected' check (status in ('not_connected','pending','connected','error','revoked')),
  external_account_id text,
  scopes text[] not null default '{}',
  connected_by uuid references auth.users(id) on delete set null,
  last_verified_at timestamptz,
  last_error_code text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (business_id, provider, external_account_id)
);

create table if not exists public.approvals (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references public.business_units(id) on delete restrict,
  requested_by uuid references auth.users(id) on delete set null,
  action_type text not null,
  summary text not null,
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'pending' check (status in ('pending','approved','rejected','cancelled')),
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.async_jobs (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references public.business_units(id) on delete restrict,
  job_type text not null,
  idempotency_key text not null unique,
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'queued' check (status in ('queued','running','succeeded','failed','dead_letter','cancelled')),
  attempts integer not null default 0 check (attempts >= 0),
  max_attempts integer not null default 5 check (max_attempts > 0),
  run_after timestamptz not null default now(),
  locked_at timestamptz,
  last_error_code text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references public.business_units(id) on delete restrict,
  actor_user_id uuid references auth.users(id) on delete set null,
  action text not null,
  entity_type text,
  entity_id uuid,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

do $$
declare t text;
begin
  foreach t in array array[
    'business_units','business_memberships','contacts','campaigns','opportunities',
    'conversations','messages','consents','appointments','integration_connections',
    'approvals','async_jobs','audit_logs'
  ] loop
    execute format('alter table public.%I enable row level security', t);
  end loop;
end $$;

drop policy if exists business_units_member_read on public.business_units;
create policy business_units_member_read on public.business_units
for select to authenticated using (private.has_business_access(id));
drop policy if exists memberships_self_read on public.business_memberships;
create policy memberships_self_read on public.business_memberships
for select to authenticated using (user_id = auth.uid());

-- Memberships are provisioned only by trusted administrative tooling.
drop policy if exists contacts_member_all on public.contacts;
create policy contacts_member_all on public.contacts for all to authenticated
using (private.has_business_access(business_id)) with check (private.has_business_access(business_id));
drop policy if exists campaigns_member_all on public.campaigns;
create policy campaigns_member_all on public.campaigns for all to authenticated
using (private.has_business_access(business_id)) with check (private.has_business_access(business_id));
drop policy if exists opportunities_member_all on public.opportunities;
create policy opportunities_member_all on public.opportunities for all to authenticated
using (private.has_business_access(business_id)) with check (
  private.has_business_access(opportunities.business_id)
);
drop policy if exists conversations_member_all on public.conversations;
create policy conversations_member_all on public.conversations for all to authenticated
using (private.has_business_access(business_id)) with check (
  private.has_business_access(conversations.business_id)
);
drop policy if exists messages_member_all on public.messages;
create policy messages_member_all on public.messages for all to authenticated
using (private.has_business_access(business_id)) with check (
  private.has_business_access(messages.business_id)
);
drop policy if exists consents_member_all on public.consents;
create policy consents_member_all on public.consents for all to authenticated
using (private.has_business_access(business_id)) with check (
  private.has_business_access(consents.business_id)
);
drop policy if exists appointments_member_all on public.appointments;
create policy appointments_member_all on public.appointments for all to authenticated
using (private.has_business_access(business_id)) with check (
  private.has_business_access(appointments.business_id)
);
drop policy if exists integrations_member_all on public.integration_connections;
create policy integrations_member_all on public.integration_connections for all to authenticated
using (private.has_business_access(business_id)) with check (private.has_business_access(business_id));

drop policy if exists approvals_member_read on public.approvals;
create policy approvals_member_read on public.approvals for select to authenticated
using (business_id is null or private.has_business_access(business_id));
drop policy if exists approvals_member_insert on public.approvals;
create policy approvals_member_insert on public.approvals for insert to authenticated
with check (requested_by = auth.uid() and (business_id is null or private.has_business_access(business_id)));

drop policy if exists async_jobs_member_read on public.async_jobs;
create policy async_jobs_member_read on public.async_jobs for select to authenticated
using (business_id is not null and private.has_business_access(business_id));
drop policy if exists audit_logs_member_read on public.audit_logs;
create policy audit_logs_member_read on public.audit_logs for select to authenticated
using (business_id is not null and private.has_business_access(business_id));

revoke all on public.business_memberships from anon, authenticated;
grant select on public.business_memberships to authenticated;
revoke insert, update, delete on public.async_jobs, public.audit_logs from anon, authenticated;
revoke update, delete on public.approvals from anon, authenticated;


-- Explicit Data API privileges. RLS policies above remain the row-level boundary.
grant usage on schema public to authenticated;
revoke all on public.business_units, public.business_memberships,
  public.contacts, public.campaigns, public.opportunities, public.conversations,
  public.messages, public.consents, public.appointments, public.integration_connections,
  public.approvals, public.async_jobs, public.audit_logs from anon;

grant select on public.business_units, public.business_memberships to authenticated;
grant select, insert, update, delete on public.contacts, public.campaigns,
  public.opportunities, public.conversations, public.messages, public.consents,
  public.appointments, public.integration_connections to authenticated;
grant select, insert on public.approvals to authenticated;
grant select on public.async_jobs, public.audit_logs to authenticated;
