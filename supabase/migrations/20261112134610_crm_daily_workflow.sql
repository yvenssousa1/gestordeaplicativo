-- Daily CRM tasks, interaction outcomes and relationship profiles
alter table public.contacts
  add column if not exists relationship_profile text not null default 'cold_prospect',
  add column if not exists last_contacted_at timestamptz,
  add column if not exists last_purchase_at timestamptz;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.contacts'::regclass
      and conname = 'contacts_relationship_profile_check'
  ) then
    alter table public.contacts
      add constraint contacts_relationship_profile_check
      check (relationship_profile in (
        'cold_prospect',
        'former_customer',
        'reactive_customer',
        'preventive_recurring',
        'new_customer',
        'active_customer'
      ));
  end if;
end $$;

do $$
declare c record;
begin
  for c in
    select conname
    from pg_constraint
    where conrelid = 'public.opportunities'::regclass
      and contype = 'c'
      and pg_get_constraintdef(oid) ilike '%stage%'
  loop
    execute format('alter table public.opportunities drop constraint %I', c.conname);
  end loop;
end $$;

alter table public.opportunities
  add constraint opportunities_stage_check
  check (stage in ('new', 'contacted', 'qualified', 'meeting_scheduled', 'proposal', 'won', 'lost'));

create table if not exists public.crm_tasks (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.business_units(id) on delete cascade,
  contact_id uuid,
  opportunity_id uuid,
  title text not null,
  description text,
  task_type text not null default 'follow_up'
    check (task_type in ('call', 'email', 'whatsapp', 'meeting', 'follow_up', 'session', 'proposal', 'review', 'other')),
  priority text not null default 'normal'
    check (priority in ('low', 'normal', 'high', 'urgent')),
  status text not null default 'pending'
    check (status in ('pending', 'in_progress', 'completed', 'cancelled')),
  due_at timestamptz not null default now(),
  assigned_to uuid references auth.users(id) on delete set null,
  created_by uuid references auth.users(id) on delete set null,
  outcome text
    check (outcome is null or outcome in (
      'no_answer', 'replied', 'interested', 'meeting_booked', 'meeting_held',
      'proposal_sent', 'won', 'lost', 'not_interested', 'follow_up_required', 'other'
    )),
  outcome_notes text,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint crm_tasks_contact_business_fk
    foreign key (contact_id, business_id)
    references public.contacts(id, business_id) on delete cascade,
  constraint crm_tasks_opportunity_business_fk
    foreign key (opportunity_id, business_id)
    references public.opportunities(id, business_id) on delete cascade,
  constraint crm_tasks_completed_outcome_check
    check (status <> 'completed' or outcome is not null)
);

create index if not exists crm_tasks_business_due_idx
  on public.crm_tasks (business_id, due_at)
  where status in ('pending', 'in_progress');
create index if not exists crm_tasks_assignee_due_idx
  on public.crm_tasks (assigned_to, due_at)
  where status in ('pending', 'in_progress');
create index if not exists contacts_business_relationship_profile_idx
  on public.contacts (business_id, relationship_profile);

alter table public.crm_tasks enable row level security;
grant select, insert, update, delete on public.crm_tasks to authenticated;

drop policy if exists crm_tasks_business_select on public.crm_tasks;
create policy crm_tasks_business_select on public.crm_tasks
  for select to authenticated
  using (private.has_business_access(business_id));

drop policy if exists crm_tasks_business_insert on public.crm_tasks;
create policy crm_tasks_business_insert on public.crm_tasks
  for insert to authenticated
  with check (private.has_business_access(business_id));

drop policy if exists crm_tasks_business_update on public.crm_tasks;
create policy crm_tasks_business_update on public.crm_tasks
  for update to authenticated
  using (private.has_business_access(business_id))
  with check (private.has_business_access(business_id));

drop policy if exists crm_tasks_business_delete on public.crm_tasks;
create policy crm_tasks_business_delete on public.crm_tasks
  for delete to authenticated
  using (private.has_business_access(business_id));
