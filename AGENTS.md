# Instrucoes para agentes de desenvolvimento — Client Cue Creative

Estas instrucoes aplicam-se a qualquer agente de IA ou pessoa que trabalhe neste repositorio.

## Missao
Desenvolver e manter o Client Cue Creative: uma plataforma central de inteligencia comercial, CRM e automacao com suporte a varias linhas de negocio. Trabalhar no codigo existente, de forma incremental, verificavel e segura. Nao reconstruir a aplicacao sem uma justificacao tecnica demonstrada.

## Estado inicial conhecido
- Este repositorio foi criado para receber o codigo-fonte do Client Cue Creative.
- Na auditoria inicial, a branch main continha apenas um README.md com o titulo do repositorio. Nao havia aplicacao, frontend, backend, migracoes ou testes para executar.
- Portanto, nao afirmar que funcionalidades estao implementadas ou operacionais ate existir codigo e testes que o comprovem.
- Quando o codigo da aplicacao for sincronizado para este repositorio, fazer primeiro uma nova auditoria antes de alterar qualquer coisa.

## Linhas de negocio a suportar
Manter os dados, identidade, contactos, campanhas, publico, funis, ofertas e metricas separados por negocio, com uma plataforma e CRM centrais:
- 001 — servicos de massagem/terapeuticos em Portugal (EUR).
- 004 — registo de desconto de eletricidade no Brasil (BRL).
- 003 — cursos online internacionais (EUR/BRL).
- 005 — oportunidades GFI HUB internacionais (USD/BRL).

Usar identificadores estaveis de negocio em todas as entidades relevantes. Nunca misturar leads, consentimentos, campanhas, moedas ou resultados entre negocios.

## Processo obrigatorio antes de implementar
1. Inspecionar toda a arvore do repositorio, historico, configuracao, dependencias e workflows.
2. Identificar stack, comandos reais, arquitetura, backend, base de dados, integracoes e estado de deploy.
3. Classificar cada funcionalidade como: encontrada no codigo, configurada, funcional verificada, simulada/demo ou inexistente.
4. Criar um plano curto com riscos, dependencias e criterios de aceitacao.
5. Trabalhar numa branch propria; nunca fazer push direto para main.
6. Fazer alteracoes pequenas e relacionadas. Preservar interfaces e dados existentes.
7. Executar lint, typecheck, testes e build apenas quando os comandos existirem. Acrescentar testes para novas regras.
8. Rever o diff e procurar segredos, dados pessoais, regressao, dependencias desnecessarias e migracoes destrutivas.
9. Abrir pull request com resumo, ficheiros alterados, testes executados, limitacoes e passos manuais pendentes.

## Regras de seguranca e dados
- Nunca escrever tokens, passwords, chaves API, credenciais OAuth, dados pessoais reais ou segredos em ficheiros versionados, logs ou exemplos. Usar variaveis de ambiente e o gestor de segredos da plataforma.
- Nunca copiar valores de .env para documentacao. Se encontrar um segredo exposto, nao o repetir; sinalizar a necessidade de rotacao.
- Nao executar migracoes destrutivas, apagar tabelas, alterar politicas de acesso ou substituir dados reais sem backup, plano de reversao e aprovacao explicita.
- Preservar RGPD/GDPR e LGPD: finalidade, minimizacao, consentimento, retencao, direitos do titular e controlo de acesso.
- Separar dados por negocio e por utilizador/organizacao com autorizacao validada no servidor. Nao confiar apenas em filtros do frontend.
- Nao expor chaves privilegiadas no browser.

## Integracoes
- WhatsApp: webhook autenticado, validacao de assinatura, idempotencia, estados de mensagem, contexto de campanha/UTM, qualificacao, janela de 24 horas e modelos aprovados quando aplicavel, opt-out e transferencia para humano.
- Google Calendar: OAuth seguro, verificacao de disponibilidade no servidor, prevencao de conflitos, criacao/edicao/cancelamento e sincronizacao com CRM.
- Meta, Instagram, TikTok e LinkedIn: implementar apenas com APIs oficiais, permissoes concedidas e tokens guardados em segredo. Um botao ou ecra de configuracao nao prova que a integracao funciona.
- Processos assincronos: IDs, estados, tentativas limitadas, backoff, idempotencia, registo de erros e recuperacao.
- Nao assumir que qualquer integracao esta ligada. Verificar cada fluxo ponta a ponta.

## Agentes e autonomia
Os agentes podem autonomamente analisar codigo, propor e implementar alteracoes de baixo risco, executar testes, corrigir falhas e abrir pull requests.
Exigir aprovacao humana antes de:
- publicar em producao ou alterar dominios;
- alterar precos, orcamentos publicitarios relevantes ou campanhas em escala;
- executar pagamentos, transacoes ou decisoes de investimento;
- enviar comunicacoes em massa;
- alterar regras globais, permissoes, politicas de privacidade ou dados reais;
- executar migracoes destrutivas ou rotacionar credenciais.

## Limites de dominio
- Servicos terapeuticos: nao diagnosticar nem prescrever tratamentos; encaminhar questoes clinicas para profissional qualificado.
- Investimentos/GFI HUB: nao prometer retornos nem produzir aconselhamento financeiro regulado; exigir validacao humana e divulgacoes adequadas.
- Nao fabricar metricas, resultados, disponibilidade, integracoes ou testes.

## Qualidade
- Preferir TypeScript estrito quando compativel com a stack existente.
- Validar entradas no servidor e tratar erros explicitamente.
- Usar logs estruturados sem segredos nem conteudo pessoal desnecessario.
- Adicionar testes de isolamento entre negocios, autorizacao, idempotencia e regras de negocio.
- Documentar configuracao, variaveis de ambiente por nome (nunca valores), deploy, rollback e limitacoes.
- Nao adicionar tabelas ou servicos duplicados antes de inspecionar o esquema existente.

## Definicao de concluido
Uma tarefa so esta concluida quando:
- o comportamento esta implementado no codigo;
- testes relevantes passam;
- build/typecheck/lint aplicaveis passam ou falhas estao documentadas;
- o diff foi revisto;
- documentacao e migracoes estao incluidas quando necessarias;
- o pull request descreve claramente o que foi e o que nao foi verificado.

Se faltar codigo, acesso, credenciais ou decisao de produto, parar nessa dependencia, explicar exatamente o bloqueio e nao simular sucesso.
