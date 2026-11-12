import { createFileRoute } from '@tanstack/react-router'
import { useEffect, useMemo, useState } from 'react'
import type { FormEvent } from 'react'
import type { Session } from '@supabase/supabase-js'
import {
  ArrowLeft, ArrowUpRight, Building2, CalendarClock, Filter, Handshake,
  Mail, MapPin, Phone, Search, Users, LogIn, LogOut, Plus, Save, History,
} from 'lucide-react'
import {
  PARTNERSHIPS, PARTNERSHIP_SOURCE, PARTNERSHIP_TARGETS,
  type PartnerCategory, type PartnershipLead,
} from '../lib/partnerships'
import { getSupabaseBrowserClient, isSupabaseConfigured } from '../lib/supabase'
import {
  createPartner, createPartnerActivity, getTherapyBusinessId,
  loadPartnerActivities, loadPartners, updatePartner,
  type PartnerRecord, type PartnershipActivity, type DbPartnerStatus,
  type DbPartnerFrequency, type DbActivityType,
} from '../lib/partnerships.repository'

export const Route = createFileRoute('/parcerias')({ component: PartnershipsPage })

const categoryLabels: Record<PartnerCategory, string> = {
  empresa: 'Empresas', clinica: 'Clínicas', pilates: 'Estúdios de Pilates',
}
const dbCategoryLabels = { company: 'Empresas', clinic: 'Clínicas', pilates: 'Estúdios de Pilates', senior_institution: 'Instituições sénior', association: 'Associações', other: 'Outros' } as const
const statusLabels: Record<DbPartnerStatus, string> = {
  prospect: 'Por contactar', contacted: 'Contactado', meeting: 'Reunião', negotiating: 'Em negociação',
  active: 'Activo', paused: 'Em pausa', rejected: 'Sem interesse',
}
const frequencyLabels: Record<Exclude<DbPartnerFrequency, null>, string> = {
  monthly: '1 vez por mês', twice_weekly: '2 vezes por semana',
  three_weekly: '3 vezes por semana', daily: 'Todos os dias',
}
const statusOptions = Object.entries(statusLabels) as [DbPartnerStatus, string][]
const frequencyOptions = Object.entries(frequencyLabels) as [Exclude<DbPartnerFrequency, null>, string][]

function PartnershipsPage() {
  const supabase = useMemo(() => getSupabaseBrowserClient(), [])
  const [session, setSession] = useState<Session | null>(null)
  const [authReady, setAuthReady] = useState(false)
  const [businessId, setBusinessId] = useState<string | null>(null)
  const [records, setRecords] = useState<PartnerRecord[]>([])
  const [loading, setLoading] = useState(false)
  const [syncError, setSyncError] = useState('')
  const [query, setQuery] = useState('')
  const [category, setCategory] = useState<'todas' | PartnerCategory>('todas')
  const [showTargets, setShowTargets] = useState(false)
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [authError, setAuthError] = useState('')
  const [savingId, setSavingId] = useState('')
  const [editingId, setEditingId] = useState('')
  const [editStatus, setEditStatus] = useState<DbPartnerStatus>('prospect')
  const [editFrequency, setEditFrequency] = useState<DbPartnerFrequency>(null)
  const [historyId, setHistoryId] = useState('')
  const [activities, setActivities] = useState<PartnershipActivity[]>([])
  const [activityType, setActivityType] = useState<DbActivityType>('call')
  const [activitySummary, setActivitySummary] = useState('')
  const [activityOutcome, setActivityOutcome] = useState('')
  const [nextAction, setNextAction] = useState('')
  const [nextActionAt, setNextActionAt] = useState('')
  const [showCreate, setShowCreate] = useState(false)
  const [newName, setNewName] = useState('')
  const [newCategory, setNewCategory] = useState<PartnerCategory>('empresa')
  const [newProposal, setNewProposal] = useState('')
  const [newEmail, setNewEmail] = useState('')
  const [newPhone, setNewPhone] = useState('')
  const [newAddress, setNewAddress] = useState('')
  const [newNotes, setNewNotes] = useState('')

  useEffect(() => {
    if (!supabase) { setAuthReady(true); return }
    let alive = true
    void supabase.auth.getSession().then(({ data }) => {
      if (alive) { setSession(data.session); setAuthReady(true) }
    })
    const { data: listener } = supabase.auth.onAuthStateChange((_event, nextSession) => {
      setSession(nextSession)
      setBusinessId(null)
      setRecords([])
      setSyncError('')
    })
    return () => { alive = false; listener.subscription.unsubscribe() }
  }, [supabase])

  useEffect(() => {
    if (!supabase || !session) return
    let alive = true
    setLoading(true)
    setSyncError('')
    void (async () => {
      try {
        const id = await getTherapyBusinessId(supabase)
        const partners = await loadPartners(supabase, id)
        if (alive) { setBusinessId(id); setRecords(partners) }
      } catch (error) {
        if (alive) setSyncError(error instanceof Error ? error.message : 'Não foi possível carregar os dados do Supabase.')
      } finally {
        if (alive) setLoading(false)
      }
    })()
    return () => { alive = false }
  }, [supabase, session])

  const filtered = useMemo(() => {
    if (session) return records.filter((partner) => {
      const matchesCategory = category === 'todas' || partner.category === ({ empresa: 'company', clinica: 'clinic', pilates: 'pilates' } as const)[category]
      const search = query.trim().toLocaleLowerCase('pt-PT')
      const matchesQuery = !search || [partner.name, partner.proposal, partner.address, partner.notes, partner.email, partner.phone]
        .some((value) => value?.toLocaleLowerCase('pt-PT').includes(search))
      return matchesCategory && matchesQuery
    })
    return PARTNERSHIPS.filter((partner) => {
      const matchesCategory = category === 'todas' || partner.category === category
      const search = query.trim().toLocaleLowerCase('pt-PT')
      return matchesCategory && (!search || [partner.name, partner.proposal, partner.address, partner.notes, partner.email, partner.phone].some((value) => value?.toLocaleLowerCase('pt-PT').includes(search)))
    })
  }, [category, query, records, session])

  const counts = useMemo(() => session ? ({
    empresa: records.filter((p) => p.category === 'company').length,
    clinica: records.filter((p) => p.category === 'clinic').length,
    pilates: records.filter((p) => p.category === 'pilates').length,
  }) : ({
    empresa: PARTNERSHIPS.filter((p) => p.category === 'empresa').length,
    clinica: PARTNERSHIPS.filter((p) => p.category === 'clinica').length,
    pilates: PARTNERSHIPS.filter((p) => p.category === 'pilates').length,
  }), [records, session])

  async function handleSignIn(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (!supabase) return
    setAuthError('')
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) setAuthError(error.message)
    else setPassword('')
  }

  async function handleSignOut() {
    if (!supabase) return
    const { error } = await supabase.auth.signOut()
    if (error) setSyncError(error.message)
  }

  async function savePartner(partnerId: string) {
    if (!supabase || !businessId) return
    setSavingId(partnerId)
    setSyncError('')
    try {
      const updated = await updatePartner(supabase, businessId, partnerId, { status: editStatus, frequency: editFrequency })
      setRecords((current) => current.map((item) => item.id === partnerId ? updated : item))
      setEditingId('')
    } catch (error) {
      setSyncError(error instanceof Error ? error.message : 'Não foi possível guardar as alterações.')
    } finally { setSavingId('') }
  }

  async function openHistory(partnerId: string) {
    if (!supabase || !businessId) return
    setHistoryId(partnerId)
    setActivities([])
    setSyncError('')
    try { setActivities(await loadPartnerActivities(supabase, businessId, partnerId)) }
    catch (error) { setSyncError(error instanceof Error ? error.message : 'Não foi possível carregar o histórico.') }
  }

  async function saveActivity(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (!supabase || !businessId || !session || !historyId || !activitySummary.trim()) return
    setSyncError('')
    try {
      const created = await createPartnerActivity(supabase, businessId, historyId, {
        activity_type: activityType, summary: activitySummary.trim(),
        outcome: activityOutcome.trim() || null, next_action: nextAction.trim() || null,
        next_action_at: nextActionAt ? new Date(nextActionAt).toISOString() : null,
      }, session.user.id)
      setActivities((current) => [created, ...current])
      setActivitySummary(''); setActivityOutcome(''); setNextAction(''); setNextActionAt('')
    } catch (error) {
      setSyncError(error instanceof Error ? error.message : 'Não foi possível registar a actividade.')
    }
  }

  async function saveNewPartner(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (!supabase || !businessId || !newName.trim()) return
    setSyncError('')
    try {
      const created = await createPartner(supabase, businessId, {
        name: newName.trim(), category: ({ empresa: 'company', clinica: 'clinic', pilates: 'pilates' } as const)[newCategory],
        proposal: newProposal, email: newEmail, phone: newPhone, address: newAddress, notes: newNotes,
      })
      setRecords((current) => [...current, created].sort((a, b) => a.name.localeCompare(b.name, 'pt-PT')))
      setShowCreate(false); setNewName(''); setNewProposal(''); setNewEmail(''); setNewPhone(''); setNewAddress(''); setNewNotes('')
    } catch (error) {
      setSyncError(error instanceof Error ? error.message : 'Não foi possível criar o parceiro.')
    }
  }

  const displayRecords = session
    ? (filtered as PartnerRecord[]).map((partner) => ({
      id: partner.id, name: partner.name, category: dbCategoryLabels[partner.category],
      proposal: partner.proposal, email: partner.email, phone: partner.phone, whatsapp: partner.whatsapp,
      website: partner.website, address: partner.address, notes: partner.notes,
      status: statusLabels[partner.status], frequency: partner.frequency ? frequencyLabels[partner.frequency] : 'Por definir',
      db: partner,
    }))
    : (filtered as PartnershipLead[]).map((partner) => ({
      id: partner.id, name: partner.name, category: categoryLabels[partner.category],
      proposal: partner.proposal, email: partner.email, phone: partner.phone, whatsapp: partner.whatsapp,
      website: partner.website, address: partner.address, notes: partner.notes,
      status: 'Por contactar', frequency: 'Por definir', db: null,
    }))

  return (
    <main className="app-shell">
      <aside className="sidebar">
        <a className="brand" href="/" aria-label="Client Cue Creative início"><span className="brand-mark"><Handshake size={19} /></span><span><strong>client cue</strong><small>CREATIVE</small></span></a>
        <div className="workspace-switch"><span className="workspace-avatar">CC</span><span className="workspace-name"><strong>Central de negócios</strong><small>Área de trabalho</small></span></div>
        <p className="nav-label">PLATAFORMA</p>
        <nav className="nav-list" aria-label="Navegação principal">
          <a className="nav-item" href="/"><Building2 size={17} /> Visão geral</a>
          <a className="nav-item" href="/#businesses"><Users size={17} /> Negócios</a>
          <a className="nav-item" href="/#crm"><Users size={17} /> CRM e contactos</a>
          <a className="nav-item active" href="/parcerias"><Handshake size={17} /> Parcerias</a>
        </nav>
        <div className="sidebar-bottom"><div className="help-card"><Handshake size={17} /><span><strong>Expansão comercial</strong><small>Diretório de oportunidades</small></span></div></div>
      </aside>

      <section className="main-area">
        <header className="topbar"><div className="breadcrumbs"><a href="/">Workspace</a><span>/</span><strong>Parcerias</strong></div>
          <div className="top-actions">
            <span className={session ? 'connection-pill online' : 'connection-pill'}><i />{session ? 'Supabase autenticado' : isSupabaseConfigured() ? 'Supabase disponível · sessão por iniciar' : 'Modo de demonstração · sem configuração'}</span>
            {session && <button className="text-button" onClick={() => void handleSignOut()}><LogOut size={14} /> Sair</button>}
          </div>
        </header>

        <div className="page-content">
          <div className="welcome-row"><div><p className="eyebrow">EXPANSÃO COMERCIAL · OEIRAS E CASCAIS</p><h1>Parcerias</h1><p className="page-subtitle">Organize oportunidades, contactos, frequência e resultados comerciais.</p></div><a className="primary-button" href="/"><ArrowLeft size={16} /> Voltar à visão geral</a></div>

          {!isSupabaseConfigured() && <div className="notice"><span className="notice-icon"><Handshake size={18} /></span><div><strong>Catálogo local de demonstração</strong><p>O Supabase ainda não está configurado neste ambiente. Os registos apresentados são locais e não são guardados na base de dados.</p></div></div>}
          {isSupabaseConfigured() && !session && authReady && <form className="supabase-auth-panel" onSubmit={(event) => void handleSignIn(event)}><div><strong>Entrar para sincronizar parcerias</strong><p>Usa a conta de utilizador criada no Supabase Auth. O acesso aos dados é validado pelas políticas RLS.</p></div><label>E-mail<input type="email" value={email} onChange={(event) => setEmail(event.target.value)} required /></label><label>Palavra-passe<input type="password" value={password} onChange={(event) => setPassword(event.target.value)} required /></label><button className="primary-button" type="submit"><LogIn size={15} /> Entrar</button>{authError && <p className="sync-error">{authError}</p>}</form>}
          {session && <div className="supabase-status-panel"><span><i /> Sessão activa: {session.user.email}</span><span>{loading ? 'A carregar dados...' : businessId ? 'Dados sincronizados com a unidade 001' : 'A validar permissões e estrutura'}</span></div>}
          {syncError && <div className="sync-error" role="alert">{syncError}</div>}

          <div className="notice"><span className="notice-icon"><Handshake size={18} /></span><div><strong>{session ? 'Diretório ligado à base de dados' : 'Diretório importado — ainda sem contactos realizados'}</strong><p>{session ? 'As alterações feitas nesta página são guardadas no Supabase. Os registos continuam classificados como oportunidades até actualização manual.' : 'Os 36 registos foram transcritos do documento fornecido. Não representam parcerias confirmadas. Valide os dados antes de contactar cada entidade.'}</p></div></div>

          <div className="partnership-stats">
            <article><span>Empresas e parques</span><strong>{counts.empresa}</strong><small>Bem-estar corporativo</small></article>
            <article><span>Clínicas e consultórios</span><strong>{counts.clinica}</strong><small>Encaminhamento e cobertura</small></article>
            <article><span>Estúdios de Pilates</span><strong>{counts.pilates}</strong><small>Indicação de alunos</small></article>
            <article><span>Segmentos para palestras</span><strong>{PARTNERSHIP_TARGETS.length}</strong><small>Sem entidades identificadas</small></article>
          </div>

          <div className="partnership-toolbar">
            <label className="partner-search"><Search size={17} /><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Pesquisar entidade, localidade ou proposta..." /></label>
            <label className="partner-filter"><Filter size={16} /><select value={category} onChange={(event) => setCategory(event.target.value as 'todas' | PartnerCategory)}><option value="todas">Todas as categorias</option><option value="empresa">Empresas</option><option value="clinica">Clínicas</option><option value="pilates">Estúdios de Pilates</option></select></label>
            {session && businessId && <button className="primary-button" onClick={() => setShowCreate((value) => !value)}><Plus size={15} /> Novo parceiro</button>}
          </div>

          {showCreate && <form className="partner-editor" onSubmit={(event) => void saveNewPartner(event)}><h3>Adicionar parceiro</h3><div className="editor-grid">
            <label>Nome<input value={newName} onChange={(event) => setNewName(event.target.value)} required /></label>
            <label>Categoria<select value={newCategory} onChange={(event) => setNewCategory(event.target.value as PartnerCategory)}><option value="empresa">Empresa</option><option value="clinica">Clínica</option><option value="pilates">Pilates</option></select></label>
            <label>Proposta<input value={newProposal} onChange={(event) => setNewProposal(event.target.value)} /></label>
            <label>E-mail<input type="email" value={newEmail} onChange={(event) => setNewEmail(event.target.value)} /></label>
            <label>Telefone<input value={newPhone} onChange={(event) => setNewPhone(event.target.value)} /></label>
            <label>Morada<input value={newAddress} onChange={(event) => setNewAddress(event.target.value)} /></label>
            <label className="editor-wide">Notas<textarea value={newNotes} onChange={(event) => setNewNotes(event.target.value)} /></label>
          </div><div className="editor-actions"><button type="button" className="text-button" onClick={() => setShowCreate(false)}>Cancelar</button><button className="primary-button" type="submit"><Save size={15} /> Guardar parceiro</button></div></form>}

          <div className="section-heading"><div><h2>Diretório de potenciais parceiros</h2><p>{filtered.length} de {session ? records.length : PARTNERSHIPS.length} entidades · {session ? 'dados do Supabase' : 'catálogo local'}</p></div></div>
          <div className="partner-grid">
            {displayRecords.map((partner) => (
              <article className="partner-card" key={partner.id}>
                <div className="partner-card-head"><span className="partner-category">{partner.category}</span><span className="partner-stage">{partner.status}</span></div>
                <h3>{partner.name}</h3><p className="partner-proposal">{partner.proposal}</p>
                {partner.notes && <p className="partner-notes">{partner.notes}</p>}
                <div className="partner-meta">
                  {partner.email && <a href={`mailto:${partner.email}`}><Mail size={14} />{partner.email}</a>}
                  {partner.phone && <a href={`tel:${partner.phone.replace(/[^+\\d]/g, '')}`}><Phone size={14} />{partner.phone}</a>}
                  {partner.whatsapp && <a href={`https://wa.me/${partner.whatsapp.replace(/\\D/g, '')}`} target="_blank" rel="noreferrer"><Phone size={14} />WhatsApp {partner.whatsapp}</a>}
                  {partner.website && <a href={partner.website} target="_blank" rel="noreferrer"><ArrowUpRight size={14} />Website / contacto</a>}
                  {partner.address && <span><MapPin size={14} />{partner.address}</span>}
                </div>
                <div className="partner-card-footer"><span><CalendarClock size={13} /> Frequência: {partner.frequency}</span>{partner.db && <span>Fonte: pág. {partner.db.source_page ?? '—'}</span>}</div>
                {partner.db && <div className="partner-actions">
                  <button className="text-button" onClick={() => { setEditingId(partner.id); setEditStatus(partner.db!.status); setEditFrequency(partner.db!.frequency) }}>Editar estado</button>
                  <button className="text-button" onClick={() => void openHistory(partner.id)}><History size={14} /> Histórico</button>
                </div>}
                {editingId === partner.id && partner.db && <div className="partner-editor-inline"><label>Estado<select value={editStatus} onChange={(event) => setEditStatus(event.target.value as DbPartnerStatus)}>{statusOptions.map(([value, label]) => <option value={value} key={value}>{label}</option>)}</select></label><label>Frequência<select value={editFrequency ?? ''} onChange={(event) => setEditFrequency((event.target.value || null) as DbPartnerFrequency)}><option value="">Por definir</option>{frequencyOptions.map(([value, label]) => <option value={value} key={value}>{label}</option>)}</select></label><div className="editor-actions"><button className="text-button" onClick={() => setEditingId('')}>Cancelar</button><button className="primary-button" disabled={savingId === partner.id} onClick={() => void savePartner(partner.id)}><Save size={14} /> Guardar</button></div></div>}
                {historyId === partner.id && <div className="partner-history"><h4>Histórico de actividades</h4>{activities.length === 0 ? <p>Sem actividades registadas.</p> : activities.map((activity) => <div className="activity-entry" key={activity.id}><strong>{activity.activity_type} · {new Date(activity.occurred_at).toLocaleString('pt-PT')}</strong><p>{activity.summary}</p>{activity.outcome && <small>Resultado: {activity.outcome}</small>}{activity.next_action && <small>Próximo passo: {activity.next_action}{activity.next_action_at ? ` · ${new Date(activity.next_action_at).toLocaleDateString('pt-PT')}` : ''}</small>}</div>)}
                  <form onSubmit={(event) => void saveActivity(event)}><label>Tipo<select value={activityType} onChange={(event) => setActivityType(event.target.value as DbActivityType)}><option value="call">Chamada</option><option value="email">E-mail</option><option value="whatsapp">WhatsApp</option><option value="meeting">Reunião</option><option value="proposal">Proposta</option><option value="session">Sessão</option><option value="talk">Palestra</option><option value="note">Nota</option><option value="other">Outro</option></select></label><label>Resumo<textarea value={activitySummary} onChange={(event) => setActivitySummary(event.target.value)} required /></label><label>Resultado<input value={activityOutcome} onChange={(event) => setActivityOutcome(event.target.value)} /></label><label>Próxima acção<input value={nextAction} onChange={(event) => setNextAction(event.target.value)} /></label><label>Data da próxima acção<input type="date" value={nextActionAt} onChange={(event) => setNextActionAt(event.target.value)} /></label><div className="editor-actions"><button type="button" className="text-button" onClick={() => setHistoryId('')}>Fechar</button><button type="submit" className="primary-button">Registar actividade</button></div></form>
                </div>}
              </article>
            ))}
            {displayRecords.length === 0 && <div className="partner-empty">{loading ? 'A carregar...' : 'Não foram encontradas entidades com estes critérios.'}</div>}
          </div>

          <div className="section-heading lower-heading"><div><h2>Oportunidades de palestras</h2><p>Segmentos sugeridos no plano, ainda sem organizações concretas no diretório.</p></div><button className="text-button" onClick={() => setShowTargets((value) => !value)}>{showTargets ? 'Ocultar' : 'Ver segmentos'}</button></div>
          {showTargets && <div className="target-grid">{PARTNERSHIP_TARGETS.map((target) => <article className="target-card" key={target.id}><span className="partner-category">Palestras</span><h3>{target.name}</h3><p>{target.proposal}</p><small>Geografia: {target.geography} · Fonte: pág. {target.sourcePage} · Sem entidades nomeadas/contactos no documento</small></article>)}</div>}
          <div className="source-note"><strong>Origem e qualidade dos dados</strong><p>{PARTNERSHIP_SOURCE.title} · {PARTNERSHIP_SOURCE.date}. {PARTNERSHIP_SOURCE.note} As referências de contacto são as que constam no PDF; não foram testadas nem validadas externamente.</p></div>
          <footer className="page-footer"><span>Client Cue Creative · Módulo de Parcerias</span><span>{session ? 'Persistência Supabase activa' : 'Catálogo local · Supabase não ligado'}</span></footer>
        </div>
      </section>
    </main>
  )
}
