# Módulo de Parcerias — Oeiras e Cascais

## Fonte
Diretório transcrito de "Plano de Negócios e Diretório de Parcerias — Oeiras e Cascais", datado de 04/11/2026, fornecido pelo utilizador.

## Importação inicial
- 13 empresas/parques empresariais: proposta de bem-estar corporativo e sessões no local.
- 14 clínicas/consultórios: proposta de referenciação mútua e cobertura de pedidos ao domicílio/horários alternativos.
- 9 estúdios de Pilates: proposta de troca de indicações para massagem terapêutica e recuperação muscular.
- 2 segmentos para palestras (instituições sénior/centros de dia e Santas Casas/associações de reformados), sem entidades concretas ou contactos nomeados no documento.

Total: 36 entidades nomeadas + 2 segmentos de prospeção não individualizados.

## Regras de qualidade
- Os registos são oportunidades em estado inicial "por contactar"; não são parcerias existentes nem contactos realizados.
- Os contactos, moradas e websites são transcritos da fonte e não foram verificados externamente.
- Não atribuir frequência sem conversa/validação com a entidade. As opções de planeamento são mensal, duas vezes por semana, três vezes por semana e profissional diário.
- O documento propõe palestras educativas para prevenção de quedas e mobilidade no segmento sénior. Não atribuir palestras às empresas/clínicas/estúdios sem nova validação.
- O PDF sugere anúncios geolocalizados e conteúdo em grupos locais, mas não fornece dados de campanhas ou leads. Não existem métricas de desempenho importadas.
- Os preços e pacotes de atendimento do documento não são automaticamente tratados como propostas comerciais aceites.

## Próxima fase de produto
A tabela `partners` guarda classificação, modelo de colaboração, frequência, previsão de sessões/receita/custos, origem e estado comercial. `partnership_activities` guarda chamadas, e-mails, WhatsApp, reuniões, sessões, palestras, propostas e próximos passos. Ambas as tabelas têm RLS baseada na associação à unidade de negócio.

A interface inicial apresenta o catálogo de origem. A persistência e edição através do Supabase, assim como a importação dos 35 registos para a tabela, ficam para uma fase posterior com autenticação e permissões operacionais confirmadas. A migração foi criada, mas não foi aplicada.
