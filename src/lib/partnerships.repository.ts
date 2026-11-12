import type { SupabaseClient } from '@supabase/supabase-js'

export type DbPartnerCategory = 'company' | 'clinic' | 'pilates' | 'senior_institution' | 'association' | 'other'
export type DbPartnerStatus = 'prospect' | 'contacted' | 'meeting' | 'negotiating' | 'active' | 'paused' | 'rejected'
export type DbPartnerFrequency = 'monthly' | 'twice_weekly' | 'three_weekly' | 'daily' | null
export type DbActivityType = 'call' | 'email' | 'whatsapp' | 'meeting' | 'session' | 'talk' | 'proposal' | 'note' | 'other'

export type PartnerRecord = {
  id: string
  business_id: string
  name: string
  category: DbPartnerCategory
  collaboration_types: string[]
  proposal: string | null
  email: string | null
  phone: string | null
  whatsapp: string | null
  website: string | null
  address: string | null
  geography: string | null
  status: DbPartnerStatus
  frequency: DbPartnerFrequency
  expected_monthly_sessions: number | null
  expected_monthly_revenue: number | null
  estimated_monthly_cost: number | null
  currency: string | null
  source_document: string | null
  source_page: number | null
  data_verified_at: string | null
  notes: string | null
  created_at: string
  updated_at: string
}

export type PartnershipActivity = {
  id: string
  business_id: string
  partner_id: string
  activity_type: DbActivityType
  occurred_at: string
  summary: string
  outcome: string | null
  next_action: string | null
  next_action_at: string | null
  created_at: string
}

export type PartnerUpdate = Partial<Pick<PartnerRecord,
  'name' | 'category' | 'collaboration_types' | 'proposal' | 'email' | 'phone' |
  'whatsapp' | 'website' | 'address' | 'geography' | 'status' | 'frequency' |
  'expected_monthly_sessions' | 'expected_monthly_revenue' | 'estimated_monthly_cost' |
  'currency' | 'data_verified_at' | 'notes'
>>

export class PartnershipAccessError extends Error {
  constructor(message: string) {
    super(message)
    this.name = 'PartnershipAccessError'
  }
}

export async function getTherapyBusinessId(client: SupabaseClient): Promise<string> {
  const { data: business, error: businessError } = await client
    .from('business_units')
    .select('id')
    .eq('code', '001')
    .maybeSingle()

  if (businessError) throw businessError
  if (!business?.id) {
    throw new PartnershipAccessError('A unidade de negócio 001 ainda não está disponível ou a migração inicial não foi aplicada.')
  }

  const { data: membership, error: membershipError } = await client
    .from('business_memberships')
    .select('id')
    .eq('business_id', business.id)
    .maybeSingle()

  if (membershipError) throw membershipError
  if (!membership) {
    throw new PartnershipAccessError('A tua conta ainda não tem acesso à unidade de negócio 001. É necessário criar a associação de utilizador no Supabase.')
  }

  return business.id
}

export async function loadPartners(client: SupabaseClient, businessId: string): Promise<PartnerRecord[]> {
  const { data, error } = await client
    .from('partners')
    .select('*')
    .eq('business_id', businessId)
    .order('name', { ascending: true })

  if (error) throw error
  return (data ?? []) as PartnerRecord[]
}

export async function updatePartner(
  client: SupabaseClient,
  businessId: string,
  partnerId: string,
  changes: PartnerUpdate,
): Promise<PartnerRecord> {
  const { data, error } = await client
    .from('partners')
    .update({ ...changes, updated_at: new Date().toISOString() })
    .eq('business_id', businessId)
    .eq('id', partnerId)
    .select('*')
    .single()

  if (error) throw error
  return data as PartnerRecord
}

export async function createPartner(
  client: SupabaseClient,
  businessId: string,
  values: Pick<PartnerUpdate, 'name' | 'category' | 'proposal' | 'email' | 'phone' | 'address' | 'notes'>,
): Promise<PartnerRecord> {
  const { data, error } = await client
    .from('partners')
    .insert({
      business_id: businessId,
      name: values.name,
      category: values.category,
      proposal: values.proposal ?? null,
      email: values.email ?? null,
      phone: values.phone ?? null,
      address: values.address ?? null,
      notes: values.notes ?? null,
      status: 'prospect',
      currency: 'EUR',
    })
    .select('*')
    .single()

  if (error) throw error
  return data as PartnerRecord
}

export async function loadPartnerActivities(
  client: SupabaseClient,
  businessId: string,
  partnerId: string,
): Promise<PartnershipActivity[]> {
  const { data, error } = await client
    .from('partnership_activities')
    .select('*')
    .eq('business_id', businessId)
    .eq('partner_id', partnerId)
    .order('occurred_at', { ascending: false })

  if (error) throw error
  return (data ?? []) as PartnershipActivity[]
}

export async function createPartnerActivity(
  client: SupabaseClient,
  businessId: string,
  partnerId: string,
  activity: Pick<PartnershipActivity, 'activity_type' | 'summary' | 'outcome' | 'next_action' | 'next_action_at'>,
  userId: string,
): Promise<PartnershipActivity> {
  const { data, error } = await client
    .from('partnership_activities')
    .insert({
      business_id: businessId,
      partner_id: partnerId,
      ...activity,
      created_by: userId,
    })
    .select('*')
    .single()

  if (error) throw error
  return data as PartnershipActivity
}
