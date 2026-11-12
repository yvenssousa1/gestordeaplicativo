-- Partnership CRM: directory, commercial qualification and activity history.
-- This migration is prepared only; do not apply to Supabase without the documented review/backup.

create table if not exists public.partners (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.business_units(id) on delete restrict,
  name text not null,
  category text not null check (category in ('company','clinic','pilates','senior_institution','association','other')),
  collaboration_types text[] not null default '{}',
  proposal text,
  email text,
  phone text,
  whatsapp text,
  website text,
  address text,
  geography text,
  status text not null default 'prospect' check (status in ('prospect','contacted','meeting','negotiating','active','paused','rejected')),
  frequency text check (frequency is null or frequency in ('monthly','twice_weekly','three_weekly','daily')),
  expected_monthly_sessions integer check (expected_monthly_sessions is null or expected_monthly_sessions >= 0),
  expected_monthly_revenue numeric(14,2) check (expected_monthly_revenue is null or expected_monthly_revenue >= 0),
  estimated_monthly_cost numeric(14,2) check (estimated_monthly_cost is null or estimated_monthly_cost >= 0),
  currency text,
  source_document text,
  source_page integer check (source_page is null or source_page > 0),
  data_verified_at timestamptz,
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, business_id),
  unique (business_id, name)
);

create index if not exists partners_business_status_idx
  on public.partners (business_id, status, category);
create index if not exists partners_business_frequency_idx
  on public.partners (business_id, frequency);

create table if not exists public.partnership_activities (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.business_units(id) on delete restrict,
  partner_id uuid not null,
  activity_type text not null check (activity_type in ('call','email','whatsapp','meeting','session','talk','proposal','note','other')),
  occurred_at timestamptz not null default now(),
  summary text not null,
  outcome text,
  next_action text,
  next_action_at timestamptz,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  foreign key (partner_id, business_id) references public.partners(id, business_id) on delete cascade
);

create index if not exists partnership_activities_partner_date_idx
  on public.partnership_activities (business_id, partner_id, occurred_at desc);

alter table public.partners enable row level security;
alter table public.partnership_activities enable row level security;

drop policy if exists partners_member_all on public.partners;
create policy partners_member_all on public.partners
  for all to authenticated
  using (public.has_business_access(business_id))
  with check (public.has_business_access(business_id));

drop policy if exists partnership_activities_member_all on public.partnership_activities;
create policy partnership_activities_member_all on public.partnership_activities
  for all to authenticated
  using (public.has_business_access(business_id))
  with check (public.has_business_access(business_id));
