import { createFileRoute } from '@tanstack/react-router'
import { useEffect, useMemo, useState } from 'react'
import type { FormEvent } from 'react'
import { ArrowRight, BarChart3, CheckCircle2, LockKeyhole, Mail, MessageCircle, Sparkles, Target, TrendingUp, Users, Zap } from 'lucide-react'
import { getSupabaseBrowserClient, isSupabaseConfigured } from '../lib/supabase'

export const Route = createFileRoute('/login')({ component: LoginPage })

function LoginPage() {
  const supabase = useMemo(() => getSupabaseBrowserClient(), [])
  const configured = isSupabaseConfigured()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)
  const [hasSession, setHasSession] = useState(false)

  useEffect(() => {
    if (!supabase) return
    let active = true
    void supabase.auth.getSession().then(({ data }) => { if (active) setHasSession(Boolean(data.session)) })
    return () => { active = false }
  }, [supabase])

  async function googleLogin() {
    if (!supabase) return
    setBusy(true); setError('')
    const { error: authError } = await supabase.auth.signInWithOAuth({ provider: 'google', options: { redirectTo: window.location.origin + '/app' } })
    if (authError) { setError(authError.message); setBusy(false) }
  }

  async function emailLogin(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (!supabase) return
    setBusy(true); setError('')
    const { error: authError } = await supabase.auth.signInWithPassword({ email: email.trim(), password })
    if (authError) { setError(authError.message); setBusy(false); return }
    window.location.assign('/app')
  }

  async function recoverPassword() {
    if (!supabase || !email.trim()) { setError('Introduza o seu e-mail para receber a ligação de recuperação.'); return }
    setBusy(true); setError('')
    const { error: authError } = await supabase.auth.resetPasswordForEmail(email.trim(), { redirectTo: window.location.origin + '/login' })
    setError(authError ? authError.message : 'Se existir uma conta para este e-mail, receberá uma ligação de recuperação.')
    setBusy(false)
  }

  return (
    <main className="public-site">
      <header className="public-nav">
        <a className="public-brand" href="/login"><span className="public-brand-mark"><Sparkles size={19} /></span><span><strong>client cue</strong><small>CREATIVE</small></span></a>
        <nav><a href="#como-funciona">Como funciona</a><a href="#recursos">Funcionalidades</a><a href="#inteligencia">Inteligência</a></nav>
        <a className="nav-login" href="#entrar">Entrar na plataforma <ArrowRight size={15} /></a>
      </header>

      <section className="public-hero">
        <div className="hero-copy">
          <span className="hero-kicker"><i /> INTELIGÊNCIA COMERCIAL, SEM COMPLICAÇÃO</span>
          <h1>Menos contactos esquecidos.<br /><em>Mais oportunidades</em> que avançam.</h1>
          <p className="hero-lead">O seu negócio não precisa de mais uma lista de contactos. Precisa de saber quem merece atenção, qual é o próximo passo e o que realmente transforma interesse em clientes.</p>
          <div className="hero-actions"><a className="hero-cta" href="#entrar">Conhecer a plataforma <ArrowRight size={17} /></a><a className="hero-secondary" href="#como-funciona">Ver como funciona <span>↓</span></a></div>
          <div className="hero-proof"><span><CheckCircle2 size={15} /> Relações acompanhadas</span><span><CheckCircle2 size={15} /> Decisões baseadas em resultados</span></div>
        </div>

        <div className="login-card" id="entrar">
          <div className="login-card-top"><span className="login-icon"><LockKeyhole size={18} /></span><span className="secure-label">ACESSO SEGURO</span></div>
          {hasSession ? <div className="login-ready"><h2>Bem-vindo de volta.</h2><p>A sua área de trabalho está pronta.</p><a className="login-submit" href="/app">Continuar para o CRM <ArrowRight size={16} /></a></div> : <>
            <h2>Entre no seu espaço.</h2><p className="login-intro">Aceda às suas oportunidades, tarefas e resultados num só lugar.</p>
            <button className="google-login" type="button" onClick={() => void googleLogin()} disabled={!configured || busy}><GoogleMark /> Continuar com Google</button>
            <div className="login-divider"><span />ou entre com e-mail<span /></div>
            <form onSubmit={(event) => void emailLogin(event)}>
              <label htmlFor="login-email">E-mail</label><div className="login-input-wrap"><Mail size={16} /><input id="login-email" type="email" autoComplete="email" placeholder="nome@empresa.com" value={email} onChange={(event) => setEmail(event.target.value)} required /></div>
              <div className="password-label"><label htmlFor="login-password">Palavra-passe</label><button type="button" onClick={() => void recoverPassword()} disabled={busy}>Esqueceu-se?</button></div>
              <div className="login-input-wrap"><LockKeyhole size={16} /><input id="login-password" type="password" autoComplete="current-password" placeholder="A sua palavra-passe" value={password} onChange={(event) => setPassword(event.target.value)} required /></div>
              {error && <p className="login-error" role="alert">{error}</p>}
              <button className="login-submit" type="submit" disabled={!configured || busy}>{busy ? 'A validar acesso…' : 'Entrar na plataforma'} <ArrowRight size={16} /></button>
            </form>
            {!configured && <p className="login-config-note">A autenticação ainda precisa de configuração neste ambiente.</p>}
            <p className="login-invite">Acesso privado. A sua organização deve convidá-lo para utilizar a plataforma.</p>
          </>}
          <div className="login-card-foot"><span><LockKeyhole size={12} /> Os seus dados são privados</span><a href="mailto:suporte@clientcue.com">Precisa de ajuda?</a></div>
        </div>
      </section>

      <section className="public-strip"><div><strong>Uma visão clara.</strong><span>Do primeiro contacto à relação duradoura.</span></div><div><strong>Um próximo passo.</strong><span>Menos dúvidas sobre o que fazer hoje.</span></div><div><strong>Aprendizagem contínua.</strong><span>Decisões melhores com dados reais.</span></div></section>

      <section className="public-section" id="como-funciona">
        <div className="section-intro"><span className="section-kicker">O TRABALHO CERTO, NA HORA CERTA</span><h2>O seu dia começa com<br /><em>prioridades, não com dúvidas.</em></h2><p>O Client Cue organiza o trabalho comercial para que cada conversa tenha contexto, cada tarefa tenha um propósito e cada oportunidade tenha continuidade.</p></div>
        <div className="steps-grid">
          <article><span className="step-number">01</span><span className="feature-icon"><Users size={21} /></span><h3>Conheça cada contacto</h3><p>Histórico, origem, necessidades e relação com o negócio num perfil único.</p></article>
          <article><span className="step-number">02</span><span className="feature-icon"><Target size={21} /></span><h3>Saiba o que fazer a seguir</h3><p>Prioridades diárias para responder, acompanhar, marcar, recuperar ou fechar.</p></article>
          <article><span className="step-number">03</span><span className="feature-icon"><CheckCircle2 size={21} /></span><h3>Registe o que aconteceu</h3><p>Respostas, reuniões, propostas e vendas deixam de ficar perdidas na memória.</p></article>
        </div>
      </section>

      <section className="public-feature-band" id="recursos">
        <div className="feature-band-copy"><span className="section-kicker">MAIS DO QUE UM CRM</span><h2>Uma equipa comercial com<br /><em>memória e direção.</em></h2><p>Da captação ao acompanhamento, o sistema ajuda a manter o ritmo e a transformar pequenas ações consistentes em relações de negócio mais fortes.</p><a href="#entrar">Entrar e explorar <ArrowRight size={16} /></a></div>
        <div className="feature-stack">
          <div><span className="stack-icon"><Target size={18} /></span><section><strong>Funil de oportunidades</strong><small>Veja o que está por contactar, em conversa, em proposta ou ganho.</small></section></div>
          <div><span className="stack-icon"><MessageCircle size={18} /></span><section><strong>Conversas com contexto</strong><small>Registe interações e saiba quando e como voltar a falar.</small></section></div>
          <div><span className="stack-icon"><Zap size={18} /></span><section><strong>Tarefas e recomendações</strong><small>Prioridades diárias para não deixar oportunidades arrefecer.</small></section></div>
          <div><span className="stack-icon"><BarChart3 size={18} /></span><section><strong>Campanhas que ensinam</strong><small>Compare anúncios, canais e mensagens pelo resultado comercial.</small></section></div>
        </div>
      </section>

      <section className="public-section intelligence-section" id="inteligencia">
        <div className="insight-visual"><div className="insight-card"><span className="insight-eyebrow"><TrendingUp size={14} /> APRENDIZAGEM COMERCIAL</span><strong>O que gera clientes?</strong><p>Não basta saber quantos leads chegaram. Acompanhe quem respondeu, quem marcou, quem comprou e quem voltou.</p><div className="insight-metrics"><span><small>Contactos</small><b>Origem</b></span><span><small>Conversas</small><b>Interesse</b></span><span><small>Resultados</small><b>Vendas</b></span></div></div></div>
        <div className="section-intro"><span className="section-kicker">A INTELIGÊNCIA MELHORA COM A PRÁTICA</span><h2>Deixe os resultados<br /><em>ensinar o próximo passo.</em></h2><p>Ao registar o resultado de cada contacto e campanha, constrói uma base de conhecimento própria. O CRM poderá identificar padrões e sugerir melhorias com base em dados reais, distinguindo evidência de estimativa.</p></div>
      </section>

      <section className="public-bottom-cta"><span className="section-kicker">MENOS IMPROVISO. MAIS CONTINUIDADE.</span><h2>Faça cada contacto<br />contar.</h2><p>Entre no Client Cue e transforme o acompanhamento comercial num processo claro e mensurável.</p><a className="hero-cta" href="#entrar">Aceder à plataforma <ArrowRight size={17} /></a></section>
      <footer className="public-footer"><a className="public-brand" href="#top"><span className="public-brand-mark"><Sparkles size={17} /></span><span><strong>client cue</strong><small>CREATIVE</small></span></a><span>Inteligência comercial para relações que avançam.</span><a href="mailto:suporte@clientcue.com">Contacto e suporte</a><small>© {new Date().getFullYear()} Client Cue Creative</small></footer>
    </main>
  )
}

function GoogleMark() {
  return <svg viewBox="0 0 48 48" aria-hidden="true"><path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5Z"/><path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.73 7.18l7.62 5.91c4.45-4.1 7.15-10.14 7.15-17.56Z"/><path fill="#FBBC05" d="M10.53 28.59A14.4 14.4 0 0 1 9.75 24c0-1.59.27-3.13.76-4.59l-7.98-6.19A23.93 23.93 0 0 0 0 24c0 3.88.93 7.55 2.56 10.78l7.97-6.19Z"/><path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.9-5.89l-7.62-5.91c-2.11 1.42-4.8 2.26-8.28 2.26-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48Z"/></svg>
}
