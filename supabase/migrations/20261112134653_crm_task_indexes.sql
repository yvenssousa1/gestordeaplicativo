create index if not exists crm_tasks_contact_business_idx on public.crm_tasks (contact_id,business_id) where contact_id is not null;
create index if not exists crm_tasks_opportunity_business_idx on public.crm_tasks (opportunity_id,business_id) where opportunity_id is not null;
create index if not exists crm_tasks_created_by_idx on public.crm_tasks (created_by) where created_by is not null;