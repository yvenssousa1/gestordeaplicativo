# Integrações — plano de ativação

Nenhuma integração externa está declarada como operacional nesta fase.

## Supabase
- Project ref: vtukmuibskzpyzprvfnu
- Confirmar URL, chave pública, redirects de Auth e esquema existente.
- Aplicar a migração inicial apenas após revisão e backup.

## WhatsApp Cloud API
- Criar app Meta e configurar número/WABA.
- Guardar access token e app secret no gestor de segredos server-side.
- Implementar webhook GET de verificação e POST com validação de assinatura.
- Deduplicar por ID externo, registar estados, retries e handoff.
- Respeitar janela de atendimento de 24 horas, templates aprovados e opt-out.

## Google Calendar
- OAuth authorization code com state/PKCE e refresh token protegido server-side.
- Verificar disponibilidade e conflitos no servidor.
- Criar/editar/cancelar eventos e reconciliar alterações externas.

## Meta, Instagram, TikTok e LinkedIn
- Usar APIs oficiais e permissões aprovadas.
- Tokens fora do frontend.
- Separar contas, campanhas e métricas por negócio.
- Verificação periódica e revogação.

## Operação
Não publicar, enviar campanhas em massa ou alterar orçamentos sem aprovação humana.
