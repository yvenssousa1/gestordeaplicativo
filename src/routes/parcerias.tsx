import { createFileRoute } from '@tanstack/react-router'
import { useMemo, useState } from 'react'
import { ArrowLeft, ArrowUpRight, Building2, CalendarClock, Filter, Handshake, Mail, MapPin, Phone, Search, Users } from 'lucide-react'
import { PARTNERSHIPS, PARTNERSHIP_SOURCE, PARTNERSHIP_TARGETS, type PartnerCategory } from '../lib/partnerships'

export const Route = createFileRoute('/parcerias')({ component: PartnershipsPage })

const categoryLabels: Record<PartnerCategory, string> = {
  empresa: 'Empresas',
  clinica: 'Clínicas',
  pilates: 'Estúdios de Pilates',
}

function PartnershipsPage() {
  const [query, setQuery] = useState('')
  const [category, setCategory] = useState<'todas' | PartnerCategory>('todas')
  const [showTargets, setShowTargets] = useState(false)

  const filtered = useMemo(() => PARTNERSHIPS.filter((partner) => {
    const matchesCategory = category === 'todas' || partner.category === category
    const search = query.trim().toLocaleLowerCase('pt-PT')
    const matchesQuery = !search || [partner.name, partner.proposal, partner.address, partner.notes, partner.email, partner.phone]
      .some((value) => value?.toLocaleLowerCase('pt-PT').includes(search))
    return matchesCategory && matchesQuery
  }), [category, query])

  const counts = useMemo(() => ({
    empresa: PARTNERSHIPS.filter((p) => p.category === 'empresa').length,
    clinica: PARTNERSHIPS.filter((p) => p.category === 'clinica').length,
    pilates: PARTNERSHIPS.filter((p) => p.category === 'pilates').length,
  }), [])

  return (
    <main className="app-shell">
      <aside className="sidebar">
        <a className="brand" href="/" aria-label="Client Cue Creative início">
          <span className="brand-mark"><Handshake size={19} /></span>
          <span><strong>client cue</strong><small>CREATIVE</small></span>
        </a>
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
        <header className="topbar">
          <div className="breadcrumbs"><a href="/">Workspace</a><span>/</span><strong>Parcerias</strong></div>
          <div className="top-actions"><span className="connection-pill"><i /> Diretório importado · dados por validar</span></div>
        </header>

        <div className="page-content">
          <div className="welcome-row">
            <div><p className="eyebrow">EXPANSÃO COMERCIAL · OEIRAS E CASCAIS</p><h1>Parcerias</h1><p className="page-subtitle">Organize oportunidades de atendimento corporativo, referenciação e palestras.</p></div>
            <a className="primary-button" href="/"><ArrowLeft size={16} /> Voltar à visão geral</a>
          </div>

          <div className="notice">
            <span className="notice-icon"><Handshake size={18} /></span>
            <div><strong>Diretório importado — ainda sem contactos realizados</strong><p>Os 36 registos abaixo foram transcritos do documento fornecido. Não representam parcerias confirmadas. Valide os dados e a adequação antes de contactar cada entidade.</p></div>
          </div>

          <div className="partnership-stats">
            <article><span>Empresas e parques</span><strong>{counts.empresa}</strong><small>Bem-estar corporativo</small></article>
            <article><span>Clínicas e consultórios</span><strong>{counts.clinica}</strong><small>Encaminhamento e cobertura</small></article>
            <article><span>Estúdios de Pilates</span><strong>{counts.pilates}</strong><small>Indicação de alunos</small></article>
            <article><span>Segmentos para palestras</span><strong>{PARTNERSHIP_TARGETS.length}</strong><small>Sem entidades identificadas</small></article>
          </div>

          <div className="partnership-toolbar">
            <label className="partner-search"><Search size={17} /><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Pesquisar entidade, localidade ou proposta..." /></label>
            <label className="partner-filter"><Filter size={16} /><select value={category} onChange={(event) => setCategory(event.target.value as 'todas' | PartnerCategory)}><option value="todas">Todas as categorias</option><option value="empresa">Empresas</option><option value="clinica">Clínicas</option><option value="pilates">Estúdios de Pilates</option></select></label>
          </div>

          <div className="section-heading"><div><h2>Diretório de potenciais parceiros</h2><p>{filtered.length} de {PARTNERSHIPS.length} entidades · Estado inicial: por contactar</p></div></div>
          <div className="partner-grid">
            {filtered.map((partner) => (
              <article className="partner-card" key={partner.id}>
                <div className="partner-card-head"><span className={`partner-category ${partner.category}`}>{categoryLabels[partner.category]}</span><span className="partner-stage">Por contactar</span></div>
                <h3>{partner.name}</h3>
                <p className="partner-proposal">{partner.proposal}</p>
                {partner.notes && <p className="partner-notes">{partner.notes}</p>}
                <div className="partner-meta">
                  {partner.email && <a href={`mailto:${partner.email}`}><Mail size={14} />{partner.email}</a>}
                  {partner.phone && <a href={`tel:${partner.phone.replace(/[^+\d]/g, '')}`}><Phone size={14} />{partner.phone}</a>}
                  {partner.whatsapp && <a href={`https://wa.me/${partner.whatsapp.replace(/\D/g, '')}`} target="_blank" rel="noreferrer"><Phone size={14} />WhatsApp {partner.whatsapp}</a>}
                  {partner.website && <a href={partner.website} target="_blank" rel="noreferrer"><ArrowUpRight size={14} />Website / contacto</a>}
                  {partner.address && <span><MapPin size={14} />{partner.address}</span>}
                </div>
                <div className="partner-card-footer"><span><CalendarClock size={13} /> Frequência por definir</span><span>Fonte: pág. {partner.sourcePage}</span></div>
              </article>
            ))}
            {filtered.length === 0 && <div className="partner-empty">Não foram encontradas entidades com estes critérios.</div>}
          </div>

          <div className="section-heading lower-heading"><div><h2>Oportunidades de palestras</h2><p>Segmentos sugeridos no plano, ainda sem organizações concretas no diretório.</p></div><button className="text-button" onClick={() => setShowTargets((value) => !value)}>{showTargets ? 'Ocultar' : 'Ver segmentos'}</button></div>
          {showTargets && <div className="target-grid">{PARTNERSHIP_TARGETS.map((target) => <article className="target-card" key={target.id}><span className="partner-category palestra">Palestras</span><h3>{target.name}</h3><p>{target.proposal}</p><small>Geografia: {target.geography} · Fonte: pág. {target.sourcePage} · Sem entidades nomeadas/contactos no documento</small></article>)}</div>}

          <div className="section-heading lower-heading"><div><h2>Modelos de frequência a avaliar</h2><p>Opções operacionais propostas para qualificar cada parceria; nenhuma frequência foi atribuída sem evidência.</p></div></div>
          <div className="frequency-grid"><article><strong>Mensal</strong><span>1 ação por mês</span></article><article><strong>Regular</strong><span>2 vezes por semana</span></article><article><strong>Intensivo</strong><span>3 vezes por semana</span></article><article><strong>Permanente</strong><span>Profissional todos os dias</span></article></div>

          <div className="source-note"><strong>Origem e qualidade dos dados</strong><p>{PARTNERSHIP_SOURCE.title} · {PARTNERSHIP_SOURCE.date}. {PARTNERSHIP_SOURCE.note} As referências de contacto são as que constam no PDF; não foram testadas nem validadas externamente.</p></div>
          <footer className="page-footer"><span>Client Cue Creative · Módulo de Parcerias</span><span>Catálogo inicial · Persistência Supabase por implementar</span></footer>
        </div>
      </section>
    </main>
  )
}
