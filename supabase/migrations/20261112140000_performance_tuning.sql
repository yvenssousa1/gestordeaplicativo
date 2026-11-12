-- Performance tuning for foreign-key joins and RLS predicates.
-- Composite foreign keys already enforce both entity ownership and business isolation;
-- remove redundant single-column references where the composite constraint is stronger.

alter table public.appointments drop constraint if exists appointments_contact_id_fkey;
alter table public.consents drop constraint if exists consents_contact_id_fkey;
alter table public.conversations drop constraint if exists conversations_contact_id_fkey;
alter table public.messages drop constraint if exists messages_conversation_id_fkey;
alter table public.opportunities drop constraint if exists opportunities_contact_id_fkey;
alter table public.opportunities drop constraint if exists opportunities_campaign_id_fkey;

drop policy if exists memberships_self_read on public.business_memberships;
create policy memberships_self_read on public.business_memberships
  for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists approvals_member_insert on public.approvals;
create policy approvals_member_insert on public.approvals
  for insert to authenticated
  with check (requested_by = (select auth.uid())
    and (business_id is null or private.has_business_access(business_id)));

-- Foreign-key indexes: support parent deletes/updates and the CRM's common joins.
create index if not exists ad_accounts_created_by_idx on public.ad_accounts (created_by);
create index if not exists ad_creatives_campaign_business_idx on public.ad_creatives (campaign_id, business_id);
create index if not exists ad_performance_campaign_business_idx on public.ad_performance_daily (campaign_id, business_id);
create index if not exists ad_performance_creative_business_campaign_idx on public.ad_performance_daily (creative_id, business_id, campaign_id);

create index if not exists appointments_business_idx on public.appointments (business_id);
create index if not exists appointments_contact_business_idx on public.appointments (contact_id, business_id);
create index if not exists appointments_service_business_idx on public.appointments (service_id, business_id);

create index if not exists approvals_business_idx on public.approvals (business_id);
create index if not exists approvals_requested_by_idx on public.approvals (requested_by);
create index if not exists approvals_reviewed_by_idx on public.approvals (reviewed_by);
create index if not exists async_jobs_business_idx on public.async_jobs (business_id);
create index if not exists audit_logs_actor_user_idx on public.audit_logs (actor_user_id);
create index if not exists audit_logs_business_idx on public.audit_logs (business_id);
create index if not exists business_memberships_user_idx on public.business_memberships (user_id);

create index if not exists campaign_recommendations_campaign_business_idx on public.campaign_recommendations (campaign_id, business_id);
create index if not exists campaign_recommendations_reviewed_by_idx on public.campaign_recommendations (reviewed_by);
create index if not exists campaigns_ad_account_business_idx on public.campaigns (ad_account_id, business_id);
create index if not exists campaigns_business_idx on public.campaigns (business_id);
create index if not exists campaigns_created_by_idx on public.campaigns (created_by);

create index if not exists consents_business_idx on public.consents (business_id);
create index if not exists consents_contact_business_idx on public.consents (contact_id, business_id);
create index if not exists contacts_created_by_idx on public.contacts (created_by);

create index if not exists conversations_assigned_to_idx on public.conversations (assigned_to);
create index if not exists conversations_business_idx on public.conversations (business_id);
create index if not exists conversations_contact_business_idx on public.conversations (contact_id, business_id);

create index if not exists conversion_events_campaign_business_idx on public.conversion_events (campaign_id, business_id);
create index if not exists conversion_events_contact_business_idx on public.conversion_events (contact_id, business_id);
create index if not exists conversion_events_creative_business_campaign_idx on public.conversion_events (creative_id, business_id, campaign_id);
create index if not exists conversion_events_opportunity_business_idx on public.conversion_events (opportunity_id, business_id);
create index if not exists conversion_events_service_business_idx on public.conversion_events (service_id, business_id);

create index if not exists integration_connections_connected_by_idx on public.integration_connections (connected_by);

create index if not exists lead_touchpoints_campaign_business_idx on public.lead_touchpoints (campaign_id, business_id);
create index if not exists lead_touchpoints_contact_business_idx on public.lead_touchpoints (contact_id, business_id);
create index if not exists lead_touchpoints_creative_business_campaign_idx on public.lead_touchpoints (creative_id, business_id, campaign_id);

create index if not exists marketing_experiments_business_idx on public.marketing_experiments (business_id);
create index if not exists marketing_experiments_campaign_business_idx on public.marketing_experiments (campaign_id, business_id);
create index if not exists marketing_experiments_created_by_idx on public.marketing_experiments (created_by);

create index if not exists messages_conversation_business_idx on public.messages (conversation_id, business_id);
create index if not exists opportunities_campaign_business_idx on public.opportunities (campaign_id, business_id);
create index if not exists opportunities_contact_business_idx on public.opportunities (contact_id, business_id);
create index if not exists opportunities_owner_user_idx on public.opportunities (owner_user_id);

create index if not exists partners_created_by_idx on public.partners (created_by);
create index if not exists partnership_activities_created_by_idx on public.partnership_activities (created_by);
create index if not exists partnership_activities_partner_business_idx on public.partnership_activities (partner_id, business_id);
create index if not exists service_prices_service_business_idx on public.service_prices (service_id, business_id);
create index if not exists services_created_by_idx on public.services (created_by);
