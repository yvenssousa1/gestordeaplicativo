# Client Cue Creative

Plataforma central de CRM e inteligência comercial multi-negócio, com interface em português (Portugal).

## Linhas de negócio
- **001** — Serviços terapêuticos em Portugal (EUR)
- **004** — Desconto de eletricidade no Brasil (BRL)
- **003** — Cursos online internacionais (EUR/BRL)
- **005** — GFI HUB internacional (USD/BRL)

Os dados, permissões, campanhas, consentimentos e métricas são isolados por unidade de negócio. Não são apresentados indicadores fictícios.

## Stack
TanStack Start, React, TypeScript, Vite, Tailwind CSS, Supabase Auth/Postgres e Vitest.

## Desenvolvimento local
Requer Node.js 22+ e npm 10+.

```sh
npm install
cp .env.example .env
npm run dev
```

Preencher .env com URL e chave pública (anon/publishable) do Supabase. Nunca colocar service_role, tokens OAuth ou segredos em variáveis VITE_*.

Verificações: `npm run typecheck`, `npm test`, `npm run build`.

## Supabase
Project ref indicado: `vtukmuibskzpyzprvfnu`. Configuração local em `supabase/config.toml`.

**Antes de aplicar a migração:** confirmar que este projecto é dedicado ao Client Cue Creative e rever o esquema existente. A migração inicial só cria tabelas novas; não apaga nem altera tabelas existentes. Mesmo assim, exige backup e revisão.

## Estado funcional
A primeira entrega contém fundação de frontend, registo das quatro unidades, cliente Supabase opcional, esquema inicial e políticas RLS. CRM operacional, autenticação completa, WhatsApp, Calendar, redes sociais, agentes, filas e relatórios ainda precisam de implementação, credenciais e testes.

Uma integração não é considerada ligada apenas por existir um ecrã ou registo na base de dados.
