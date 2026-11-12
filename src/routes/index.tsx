import { createFileRoute } from '@tanstack/react-router'
import {
  Activity, ArrowUpRight, Bell, CalendarDays, ChartNoAxesCombined, Handshake,
  ChevronDown, CircleHelp, ContactRound, LayoutDashboard, MessageCircle,
  Plug, Search, Settings2, ShieldCheck, Sparkles, Users,
} from 'lucide-react'
import { BUSINESSES } from '../lib/businesses'
import { isSupabaseConfigured } from '../lib/supabase'

export const Route = createFileRoute('/')({ component: Dashboard })

function Dashboard() {
  const connected = isSupabaseConfigured()

  return (
    <main className="app-shell">
      <aside className="sidebar">
        <a className="brand" href="/" aria-label="Client Cue Creative início">
          <span className="brand-mark"><Sparkles size={19} /></span>
          <span><strong>client cue</strong><small>CREATIVE</small></span>
        </a>
        <div className="workspace-switch">
          <span className="workspace-avatar">CC</span>
          <span className="workspace-name"><strong>Central de negócios</strong><small>Área de trabalho</small></span>
          <ChevronDown size={15} />
        </div>
        <p className="nav-label">PLATAFORMA</p>
        <nav className="nav-list" aria-label="Navegação principal">
          <a className="nav-item active" href="#overview"><LayoutDashboard size={17} /> Visão geral</a>
          <a className="nav-item" href="#businesses"><Activity size={17} /> Negócios</a>
          <a className="nav-item" href="#crm"><ContactRound size={17} /> CRM e contactos</a>\n          <a className="nav-item" href="/parcerias"><Handshake size={17} /> Parcerias</a>
          <a className="nav-item" href="#campaigns"><ChartNoAxesCombined size={17} /> Campanhas</a>
          <a className="nav-item" href="#whatsapp"><MessageCircle size={17} /> WhatsApp</a>
          <a className="nav-item" href="#agenda"><CalendarDays size={17} /> Agenda</a>
        </nav>
        <p className="nav-label nav-label-spaced">GESTÃO</p>
        <nav className="nav-list" aria-label="Gestão">
          <a className="nav-item" href="#integrations"><Plug size={17} /> Integrações</a>
          <a className="nav-item" href="#approvals"><ShieldCheck size={17} /> Aprovações</a>
          <a className="nav-item" href="#reports"><ChartNoAxesCombined size={17} /> Inteligência</a>
          <a className="nav-item" href="#settings"><Settings2 size={17} /> Definições</a>
        </nav>
        <div className="sidebar-bottom">
          <div className="help-card"><CircleHelp size={17} /><span><strong>Centro de ajuda</strong><small>Guias e suporte</small></span></div>
          <div className="user-card"><span className="user-avatar">U</span><span><strong>Administrador</strong><small>Conta principal</small></span><Settings2 size={16} /></div>
        </div>
      </aside>

      <section className="main-area" id="overview">
        <header className="topbar">
          <div className="breadcrumbs">Workspace <span>/</span> <strong>Visão geral</strong></div>
          <div className="top-actions">
            <span className={connected ? 'connection-pill online' : 'connection-pill'}>
              <i /> {connected ? 'Supabase configurado' : 'Backend por configurar'}
            </span>
            <button className="icon-button" aria-label="Pesquisar"><Search size={18} /></button>
            <button className="icon-button" aria-label="Notificações"><Bell size={18} /></button>
            <span className="top-avatar">U</span>
          </div>
        </header>

        <div className="page-content">
          <div className="welcome-row">
            <div>
              <p className="eyebrow">QUARTA-FEIRA · CENTRAL DE OPERAÇÕES</p>
              <h1>Visão geral</h1>
              <p className="page-subtitle">Acompanhe os quatro negócios a partir de um único centro de inteligência.</p>
            </div>
            <button className="primary-button" onClick={() => document.getElementById('businesses')?.scrollIntoView({ behavior: 'smooth' })}>
              Ver negócios <ArrowUpRight size={16} />
            </button>
          </div>

          <div className="notice">
            <span className="notice-icon"><ShieldCheck size={18} /></span>
            <div><strong>Fundação em preparação</strong><p>Esta primeira versão estabelece a estrutura. Os indicadores só serão apresentados quando existirem dados reais ligados ao CRM e às integrações.</p></div>
          </div>

          <div className="section-heading" id="businesses">
            <div><h2>As suas linhas de negócio</h2><p>Identidades e resultados separados, inteligência centralizada.</p></div>
            <span className="muted-label">4 unidades registadas</span>
          </div>

          <div className="business-grid">
            {BUSINESSES.map((business) => (
              <article className="business-card" key={business.code} data-accent={business.accent}>
                <div className="business-card-top">
                  <span className="business-code">#{business.code}</span>
                  <span className="status-tag"><i /> Por ligar</span>
                </div>
                <h3>{business.name}</h3>
                <p>{business.description}</p>
                <div className="business-meta"><span>{business.market}</span><span>{business.currencies.join(' / ')}</span></div>
                <div className="business-card-footer"><span>Sem dados sincronizados</span><ArrowUpRight size={16} /></div>
              </article>
            ))}
          </div>

          <div className="section-heading lower-heading" id="crm">
            <div><h2>Centro de controlo</h2><p>Os módulos ficam preparados para receber os dados reais.</p></div>
          </div>
          <div className="module-grid">
            <Module icon={<Users size={19} />} title="CRM e contactos" description="Contactos centrais com perfil e consentimento por negócio." status="A implementar" />
            <Module icon={<MessageCircle size={19} />} title="Conversas WhatsApp" description="Entrada de mensagens, qualificação e passagem para humano." status="A implementar" />
            <Module icon={<CalendarDays size={19} />} title="Agenda" description="Disponibilidade, marcações e sincronização de calendário." status="A implementar" />\n            <a className="module-card module-link" href="/parcerias"><span className="module-icon"><Handshake size={19} /></span><div className="module-copy"><h3>Parcerias e expansão</h3><p>Diretório de Oeiras e Cascais, propostas e oportunidades de colaboração.</p><span className="module-status">Diretório inicial disponível</span></div><ArrowUpRight size={16} className="module-arrow" /></a>
            <Module icon={<Plug size={19} />} title="Integrações" description="Conectores oficiais com credenciais protegidas." status="A implementar" />
          </div>

          <footer className="page-footer">
            <span>Client Cue Creative <span className="footer-dot">·</span> Fundação técnica v0.1</span>
            <span><i className={connected ? 'footer-status ok' : 'footer-status'} /> {connected ? 'Configuração Supabase detectada' : 'A aguardar configuração segura do Supabase'}</span>
          </footer>
        </div>
      </section>
    </main>
  )
}

function Module({ icon, title, description, status }: { icon: React.ReactNode; title: string; description: string; status: string }) {
  return <article className="module-card"><span className="module-icon">{icon}</span><div className="module-copy"><h3>{title}</h3><p>{description}</p><span className="module-status">{status}</span></div><ArrowUpRight size={16} className="module-arrow" /></article>
}