-- Commercial catalog and marketing performance intelligence.
-- All exposed tables are protected by RLS and explicit authenticated grants.

create table public.services (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.business_units(id) on delete restrict,
  name text not null,
  category text,
  description text,
  duration_minutes integer check (duration_minutes is null or duration_minutes > 0),
  active boolean not null default true,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, business_id),
  unique (business_id, name)
);

create table public.service_prices (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.business_units(id) on delete restrict,
  service_id uuid not null,
  name text not null,
  price numeric(14,2) not null check (price >= 0),
  currency text not null default 'EUR',
  session_count integer check (session_count is null or session_count > 0),
  validity_days integer check (validity_days is null or validity_days > 0),
  active boolean not null default true,
  valid_from date,
  valid_until date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, business_id),
  foreign key (service_id, business_id) references public.services(id, business_id) on delete cascade,
  check (valid_until is null or valid_from is null or valid_until >= valid_from)
);
create index service_prices_service_active_idx on public.service_prices (business_id, service_id, active);

alter table public.appointments add column service_id uuid;
alter table public.appointments
  add constraint appointments_service_business_fk
  foreign key (service_id, business_id) references public.services(id, business_id) on delete set null (service_id);

create table public.ad_accounts (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.business_units(id) on delete restrict,
  platform text not null check (platform in ('meta','google_ads','tiktok_ads','linkedin_ads','other')),
  external_account_id text,
  account_name text not null,
  currency text not null default 'EUR',
  timezone text not null default 'Europe/Lisbon',
  status text not null default 'manual' check (status in ('manual','connected','paused','revoked')),
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, business_id),
  unique (business_id, platform, external_account_id)
);

alter table public.campaigns
  add column objective text check (objective is null or objective in ('awareness','traffic','engagement','leads','sales','retention','other')),
  add column audience_description text,
  add column landing_url text,
  add column ad_account_id uuid,
  add column attribution_window text not null default '7d_click_1d_view',
  add constraint campaigns_ad_account_business_fk
    foreign key (ad_account_id, business_id) references public.ad_accounts(id, business_id) on delete set null (ad_account_id);

create table public.ad_creatives (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.business_units(id) on delete restrict,
  campaign_id uuid not null,
  external_creative_id text,
  name text not null,
  creative_type text not null default 'other' check (creative_type in ('image','video','carousel','text','story','other')),
  primary_text text,
  headline text,
  description text,
  landing_url text,
  status text not null default 'active' check (status in ('draft','active','paused','archived')),
  started_at timestamptz,
  ended_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, business_id),
  unique (id, business_id, campaign_id),
  foreign key (campaign_id, business_id) references public.campaigns(id, business_id) on delete cascade,
  check (ended_at is null or started_at is null or ended_at >= started_at)
);
create index ad_creatives_campaign_idx on public.ad_creatives (business_id, campaign_id, status);

create table public.ad_performance_daily (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.business_units(id) on delete restrict,
  campaign_id uuid not null,
  creative_id uuid,
  metric_date date not null,
  source text not null default 'manual',
  spend numeric(14,2) not null default 0 check (spend >= 0),
  impressions bigint not null default 0 check (impressions >= 0),
  reach bigint not null default 0 check (reach >= 0),
  clicks bigint not null default 0 check (clicks >= 0),
  link_clicks bigint not null default 0 check (link_clicks >= 0),
  leads bigint not null default 0 check (leads >= 0),
  conversions bigint not null default 0 check (conversions >= 0),
  conversion_value numeric(14,2) not null default 0 check (conversion_value >= 0),
  currency text not null default 'EUR',
  attribution_window text,
  raw_metrics jsonb not null default '{}'::jsonb,
  imported_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  foreign key (campaign_id, business_id) references public.campaigns(id, business_id) on delete cascade,
  foreign key (creative_id, business_id, campaign_id) references public.ad_creatives(id, business_id, campaign_id) on delete cascade,
  unique nulls not distinct (business_id, campaign_id, creative_id, metric_date, source)
);
create index ad_performance_daily_campaign_date_idx on public.ad_performance_daily (business_id, campaign_id, metric_date desc);
create index ad_performance_daily_creative_date_idx on public.ad_performance_daily (business_id, creative_id, metric_date desc);

create table public.lead_touchpoints (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.business_units(id) on delete restrict,
  contact_id uuid not null,
  campaign_id uuid,
  creative_id uuid,
  channel text not null check (channel in ('meta','google','tiktok','linkedin','whatsapp','instagram','website','referral','email','phone','other')),
  source text,
  medium text,
  campaign_name text,
  content text,
  term text,
  landing_url text,
  referrer_url text,
  click_identifiers jsonb not null default '{}'::jsonb,
  touch_type text not null default 'unknown' check (touch_type in ('first','last','assisted','unknown')),
  occurred_at timestamptz not null default now(),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  foreign key (contact_id, business_id) references public.contacts(id, business_id) on delete cascade,
  foreign key (campaign_id, business_id) references public.campaigns(id, business_id) on delete set null (campaign_id),
  foreign key (creative_id, business_id, campaign_id) references public.ad_creatives(id, business_id, campaign_id) on delete set null (creative_id),
  check (creative_id is null or campaign_id is not null)
);
create index lead_touchpoints_contact_time_idx on public.lead_touchpoints (business_id, contact_id, occurred_at);
create index lead_touchpoints_campaign_time_idx on public.lead_touchpoints (business_id, campaign_id, occurred_at);

create table public.conversion_events (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.business_units(id) on delete restrict,
  contact_id uuid not null,
  opportunity_id uuid,
  service_id uuid,
  campaign_id uuid,
  creative_id uuid,
  event_type text not null check (event_type in ('lead','qualified','appointment_booked','appointment_completed','purchase','repeat_purchase','refund','cancelled')),
  occurred_at timestamptz not null default now(),
  amount numeric(14,2) not null default 0 check (amount >= 0),
  currency text not null default 'EUR',
  attribution_model text not null default 'manual' check (attribution_model in ('first_touch','last_touch','linear','position_based','data_driven','manual')),
  external_event_id text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  foreign key (contact_id, business_id) references public.contacts(id, business_id) on delete cascade,
  foreign key (opportunity_id, business_id) references public.opportunities(id, business_id) on delete set null (opportunity_id),
  foreign key (service_id, business_id) references public.services(id, business_id) on delete set null (service_id),
  foreign key (campaign_id, business_id) references public.campaigns(id, business_id) on delete set null (campaign_id),
  foreign key (creative_id, business_id, campaign_id) references public.ad_creatives(id, business_id, campaign_id) on delete set null (creative_id),
  check (creative_id is null or campaign_id is not null)
);
create index conversion_events_contact_time_idx on public.conversion_events (business_id, contact_id, occurred_at desc);
create index conversion_events_campaign_time_idx on public.conversion_events (business_id, campaign_id, occurred_at desc);
create index conversion_events_type_time_idx on public.conversion_events (business_id, event_type, occurred_at desc);

create table public.marketing_experiments (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.business_units(id) on delete restrict,
  campaign_id uuid not null,
  name text not null,
  hypothesis text not null,
  variable_tested text not null,
  primary_metric text not null,
  status text not null default 'planned' check (status in ('planned','running','completed','cancelled')),
  starts_at timestamptz,
  ends_at timestamptz,
  sample_size integer not null default 0 check (sample_size >= 0),
  conclusion text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, business_id),
  foreign key (campaign_id, business_id) references public.campaigns(id, business_id) on delete cascade,
  check (ends_at is null or starts_at is null or ends_at >= starts_at)
);

create table public.campaign_recommendations (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.business_units(id) on delete restrict,
  campaign_id uuid,
  recommendation_type text not null check (recommendation_type in ('budget','creative','audience','channel','timing','follow_up','other')),
  title text not null,
  rationale text not null,
  evidence jsonb not null default '{}'::jsonb,
  confidence_score numeric(5,4) check (confidence_score is null or confidence_score between 0 and 1),
  minimum_observations integer not null default 0 check (minimum_observations >= 0),
  suggested_action text,
  status text not null default 'pending' check (status in ('pending','accepted','rejected','applied')),
  generated_at timestamptz not null default now(),
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  foreign key (campaign_id, business_id) references public.campaigns(id, business_id) on delete set null
);
create index campaign_recommendations_status_date_idx on public.campaign_recommendations (business_id, status, generated_at desc);

create table public.marketing_data_sources (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.business_units(id) on delete restrict,
  source_name text not null,
  source_type text not null check (source_type in ('manual','csv_import','meta_api','google_ads_api','tiktok_api','linkedin_api','webhook','other')),
  last_imported_at timestamptz,
  last_import_status text,
  last_error text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, business_id),
  unique (business_id, source_name)
);

-- Every table reachable by the Data API has RLS and a least-privilege grant.
alter table public.services enable row level security;
alter table public.service_prices enable row level security;
alter table public.ad_accounts enable row level security;
alter table public.ad_creatives enable row level security;
alter table public.ad_performance_daily enable row level security;
alter table public.lead_touchpoints enable row level security;
alter table public.conversion_events enable row level security;
alter table public.marketing_experiments enable row level security;
alter table public.campaign_recommendations enable row level security;
alter table public.marketing_data_sources enable row level security;

create policy services_member_all on public.services for all to authenticated
  using (private.has_business_access(business_id))
  with check (private.has_business_access(business_id));
create policy service_prices_member_all on public.service_prices for all to authenticated
  using (private.has_business_access(business_id))
  with check (private.has_business_access(business_id));
create policy ad_accounts_member_all on public.ad_accounts for all to authenticated
  using (private.has_business_access(business_id))
  with check (private.has_business_access(business_id));
create policy ad_creatives_member_all on public.ad_creatives for all to authenticated
  using (private.has_business_access(business_id))
  with check (private.has_business_access(business_id));
create policy ad_performance_daily_member_all on public.ad_performance_daily for all to authenticated
  using (private.has_business_access(business_id))
  with check (private.has_business_access(business_id));
create policy lead_touchpoints_member_all on public.lead_touchpoints for all to authenticated
  using (private.has_business_access(business_id))
  with check (private.has_business_access(business_id));
create policy conversion_events_member_all on public.conversion_events for all to authenticated
  using (private.has_business_access(business_id))
  with check (private.has_business_access(business_id));
create policy marketing_experiments_member_all on public.marketing_experiments for all to authenticated
  using (private.has_business_access(business_id))
  with check (private.has_business_access(business_id));
create policy campaign_recommendations_member_all on public.campaign_recommendations for all to authenticated
  using (private.has_business_access(business_id))
  with check (private.has_business_access(business_id));
create policy marketing_data_sources_member_all on public.marketing_data_sources for all to authenticated
  using (private.has_business_access(business_id))
  with check (private.has_business_access(business_id));

revoke all on public.services, public.service_prices, public.ad_accounts, public.ad_creatives,
  public.ad_performance_daily, public.lead_touchpoints, public.conversion_events,
  public.marketing_experiments, public.campaign_recommendations, public.marketing_data_sources from anon;
grant select, insert, update, delete on public.services, public.service_prices, public.ad_accounts,
  public.ad_creatives, public.ad_performance_daily, public.lead_touchpoints, public.conversion_events,
  public.marketing_experiments, public.campaign_recommendations, public.marketing_data_sources to authenticated;
