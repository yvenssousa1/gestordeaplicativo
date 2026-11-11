# Arquitetura inicial

## Princípios
1. Um workspace central, quatro unidades de negócio independentes.
2. Entidades comerciais têm business_id e RLS valida a associação no Postgres.
3. O browser usa apenas a chave pública Supabase. Segredos ficam server-side.
4. A origem da lead é resolvida por campanha/UTM/configuração, nunca pelo indicativo telefónico.
5. Uma integração só é ligada após teste real autenticado.

## Domínios
- Identity & access: autenticação e memberships.
- CRM: contacts, opportunities, consents.
- Conversations: conversations, messages, handoff.
- Marketing: campaigns e touchpoints (a implementar).
- Scheduling: appointments e Google Calendar (a implementar).
- Integrations: estado e saúde das ligações.
- Automation: async_jobs, retries, idempotency e dead-letter.
- Governance: approvals e audit_logs.
- Intelligence: métricas derivadas de dados reais.

## Fluxo de eventos futuro
Webhook autenticado -> validar assinatura -> resolver negócio por configuração/UTM -> deduplicar ID externo -> persistir mensagem -> job idempotente -> agente de qualificação -> resposta segundo regras do canal -> handoff humano quando necessário.

## Segurança
- RLS em todas as tabelas.
- Não confiar no business_id enviado pelo browser.
- Não expor service_role nem tokens de fornecedores.
- Consentimento e opt-out por negócio, finalidade e canal.
- Aprovação humana para envios em massa, preços/orçamentos, decisões financeiras, publicação e migrações destrutivas.
