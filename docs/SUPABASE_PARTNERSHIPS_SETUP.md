# Configuração do Supabase — módulo Parcerias

Este guia prepara a ligação do módulo Parcerias ao projecto Supabase. A implementação integrada está na branch `feat/crm-supabase-bootstrap` e aponta para o projecto oficial `ichcexfuqcmcosxunnth` (Europa — Irlanda). As migrações desta branch ainda não foram aplicadas ao projecto remoto.

## 1. Aplicar as migrações pela ordem correcta

Depois de rever e aprovar as alterações, aplicar no SQL Editor do projecto Supabase:

1. `supabase/migrations/20261111000000_initial_schema.sql`
2. `supabase/migrations/20261112000000_partnerships.sql`
3. `supabase/migrations/20261112130000_marketing_intelligence.sql`
4. `supabase/migrations/20261112140000_performance_tuning.sql`

A primeira migração cria as unidades de negócio, memberships, o helper privado `private.has_business_access` e o CRM operacional base. O helper usa privilégios do utilizador e não é exposto no schema da API. A segunda cria `partners` e `partnership_activities`, respectivas políticas RLS e importa os 36 potenciais parceiros do catálogo de Oeiras e Cascais. A terceira acrescenta serviços e preços, contas de anúncios, criativos, métricas diárias, pontos de contacto, conversões, experiências e recomendações. A quarta optimiza índices de chaves estrangeiras e políticas RLS.

Executar as migrações pela ordem indicada. O projecto remoto foi confirmado como vazio antes desta preparação. As migrações incluem RLS e GRANTs explícitos para a API; as novas tabelas não ficam acessíveis apenas por existirem. Nunca aplicar migrações de outra branch sem comparar os ficheiros.

## 2. Configurar as variáveis de ambiente

No ambiente de desenvolvimento e no alojamento da aplicação, definir:

```env
VITE_SUPABASE_URL=https://ichcexfuqcmcosxunnth.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=sb_publishable_... (ou VITE_SUPABASE_ANON_KEY para compatibilidade)
```

Usa a chave publicável (`sb_publishable_...`) no browser; a chave pública pode estar no cliente porque o acesso às tabelas é controlado por autenticação, GRANTs mínimos e RLS. **Nunca** colocar `service_role`, passwords ou secrets em variáveis com prefixo `VITE_` nem no repositório.

## 3. Criar/confirmar o utilizador

No Supabase Dashboard, em Authentication → Users, confirmar que existe um utilizador para entrar na aplicação. A página Parcerias usa autenticação por e-mail e palavra-passe do Supabase Auth.

## 4. Atribuir acesso à unidade de negócio 001

A aplicação só apresenta e altera os dados da unidade `001` (Serviços terapêuticos). A associação de utilizadores é uma operação administrativa: as políticas RLS não permitem que um utilizador se atribua a si próprio.

No SQL Editor, substituir `UUID_DO_UTILIZADOR` pelo UUID do utilizador confirmado em Authentication → Users e executar:

```sql
insert into public.business_memberships (business_id, user_id, role)
select bu.id, 'UUID_DO_UTILIZADOR'::uuid, 'owner'
from public.business_units bu
where bu.code = '001'
on conflict (business_id, user_id) do nothing;
```

Executar este comando apenas para o utilizador a quem se pretende conceder acesso de proprietário à unidade. Não partilhar o UUID publicamente.

## 5. Testar a ligação

1. Reiniciar a aplicação depois de definir as variáveis.
2. Abrir `/parcerias`.
3. Entrar com o utilizador Supabase.
4. Confirmar que aparecem os 36 registos importados.
5. Alterar o estado e a frequência de um registo de teste; confirmar a persistência após actualizar a página.
6. Registar uma actividade de teste e confirmar que aparece no histórico do parceiro.

## 6. Modelo de segurança e limites

- O browser usa apenas a chave pública Supabase.
- As tabelas `partners` e `partnership_activities` exigem sessão autenticada.
- As políticas RLS chamam `public.has_business_access(business_id)` para limitar a leitura e escrita à unidade de negócio autorizada.
- O histórico está ligado ao parceiro e à mesma unidade de negócio por chave estrangeira composta.
- O catálogo local continua disponível como demonstração quando não há configuração ou sessão Supabase.
- A migração e o seed não são aplicados pela aplicação; a execução é uma decisão administrativa explícita.
