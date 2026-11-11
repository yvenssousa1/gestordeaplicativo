# Client Cue Creative — contexto de produto

## Objetivo
Plataforma central de inteligencia comercial, CRM e automacao para quatro linhas de negocio independentes. O principal objetivo comercial e atrair contactos qualificados para conversas no WhatsApp, acompanhando a origem, qualificacao, oportunidades, conversoes e resultados.

## Negocios
| Codigo | Atividade | Mercado/moeda |
|---|---|---|
| 001 | Massagem e servicos terapeuticos | Portugal / EUR |
| 004 | Registo de desconto de eletricidade | Brasil / BRL |
| 003 | Cursos online | Internacional / EUR e BRL |
| 005 | Oportunidades GFI HUB | Internacional / USD e BRL |

Cada negocio deve ter identidade, contactos, campanhas, audiencias, funis, ofertas, consentimentos e metricas proprios. O CRM e a inteligencia podem ser centrais, mas o isolamento de dados e obrigatorio.

## Capacidades pretendidas
- CRM relacional com contactos, perfis por negocio, oportunidades, conversas, mensagens, campanhas, pontos de contacto, agendamentos, vendas, consentimentos, aprovacoes, tarefas assincronas e auditoria/aprendizagem.
- Agentes especializados: orquestracao, marketing, vendas, WhatsApp, CRM, agenda e aprendizagem.
- WhatsApp com webhook seguro, qualificacao, contexto de campanha, historico CRM, idempotencia e passagem para atendimento humano.
- Google Calendar com OAuth, disponibilidade, criacao/edicao/cancelamento, sincronizacao e prevencao de conflitos.
- Integracoes sociais oficiais para Meta/Facebook, Instagram, TikTok e LinkedIn.
- Fila assincrona com retentativas, backoff, idempotencia, logs e recuperacao.
- Relatorio semanal a segunda-feira com resultados por negocio, campanhas, contactos, vendas, custos, conversoes e recomendacoes.
- Fila de aprovacao para operacoes sensiveis.
- Conteudo multilingue e avatar digital autorizado como fase posterior.

## Preferencias de arquitetura
- Auditar primeiro e preservar o backend funcional existente.
- Nao migrar automaticamente. Supabase/Postgres/Edge Functions so devem ser escolhidos se a auditoria confirmar compatibilidade ou ausencia de backend funcional.
- Modularizar antes de introduzir infraestrutura complexa. Adotar filas/Temporal apenas quando justificadas.
- Nao presumir que integracoes apresentadas na interface estao ligadas a APIs reais.

## Estado da auditoria deste repositorio
Em 11-11-2026, a branch main consultada continha apenas README.md com o titulo do repositorio. O repositorio ainda nao continha o codigo-fonte da aplicacao. Este documento e contexto de produto, nao prova de implementacao.
