-- Partnership CRM: directory, commercial qualification and activity history.
-- This migration is prepared only; do not apply to Supabase without the documented review/backup.

create table if not exists public.partners (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.business_units(id) on delete restrict,
  name text not null,
  category text not null check (category in ('company','clinic','pilates','senior_institution','association','other')),
  collaboration_types text[] not null default '{}',
  proposal text,
  email text,
  phone text,
  whatsapp text,
  website text,
  address text,
  geography text,
  status text not null default 'prospect' check (status in ('prospect','contacted','meeting','negotiating','active','paused','rejected')),
  frequency text check (frequency is null or frequency in ('monthly','twice_weekly','three_weekly','daily')),
  expected_monthly_sessions integer check (expected_monthly_sessions is null or expected_monthly_sessions >= 0),
  expected_monthly_revenue numeric(14,2) check (expected_monthly_revenue is null or expected_monthly_revenue >= 0),
  estimated_monthly_cost numeric(14,2) check (estimated_monthly_cost is null or estimated_monthly_cost >= 0),
  currency text,
  source_document text,
  source_page integer check (source_page is null or source_page > 0),
  data_verified_at timestamptz,
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, business_id),
  unique (business_id, name)
);

create index if not exists partners_business_status_idx
  on public.partners (business_id, status, category);
create index if not exists partners_business_frequency_idx
  on public.partners (business_id, frequency);

create table if not exists public.partnership_activities (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.business_units(id) on delete restrict,
  partner_id uuid not null,
  activity_type text not null check (activity_type in ('call','email','whatsapp','meeting','session','talk','proposal','note','other')),
  occurred_at timestamptz not null default now(),
  summary text not null,
  outcome text,
  next_action text,
  next_action_at timestamptz,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  foreign key (partner_id, business_id) references public.partners(id, business_id) on delete cascade
);

create index if not exists partnership_activities_partner_date_idx
  on public.partnership_activities (business_id, partner_id, occurred_at desc);

alter table public.partners enable row level security;
alter table public.partnership_activities enable row level security;

drop policy if exists partners_member_all on public.partners;
create policy partners_member_all on public.partners
  for all to authenticated
  using (public.has_business_access(business_id))
  with check (public.has_business_access(business_id));

drop policy if exists partnership_activities_member_all on public.partnership_activities;
create policy partnership_activities_member_all on public.partnership_activities
  for all to authenticated
  using (public.has_business_access(business_id))
  with check (public.has_business_access(business_id));


-- Seed the 36 named prospects from the user-provided Oeiras/Cascais directory.
-- Imported as prospects only; frequency, revenue and costs intentionally remain unset.
insert into public.partners (
  business_id, category, collaboration_types, name, proposal, email, phone,
  whatsapp, website, address, notes, source_page, source_document, status, currency
)
select bu.id, p.category, p.collaboration_types, p.name, p.proposal, p.email, p.phone,
  p.whatsapp, p.website, p.address, p.notes, p.source_page,
  'Plano_de_Negócios_e_Diretório_de_Parcerias_-_Oeiras_e_Cascais.pdf',
  'prospect', 'EUR'
from public.business_units bu
cross join (values
('company', array['attendance']::text[], 'Alcon Portugal', 'Bem-estar corporativo: sessões no escritório e protocolo para colaboradores.', 'sac.portugal@alcon.com', '+351 214 400 300', null, null, 'Quinta da Fonte, Edif. Q56 D. Pedro I, Rua dos Malhões 5, 2770-071 Paço de Arcos', 'Multinacional farmacêutica/oftalmológica; o documento indica mais de 100 colaboradores na sede.', 2),
('company', array['attendance']::text[], 'ABB Portugal', 'Bem-estar corporativo: blocos de 3h/5h e protocolo para colaboradores.', 'contactos.clientes@pt.abb.com', '+351 214 256 000', null, null, 'Quinta da Fonte, Edif. D. Manuel I Q53, Rua dos Malhões, 2774-002 Paço de Arcos', 'Multinacional de engenharia e automação com escritório central na Quinta da Fonte.', 2),
('company', array['attendance']::text[], 'A. Menarini Portugal', 'Bem-estar corporativo para equipas comerciais e administrativas.', 'mdportugal@menarinidiag.pt', '+351 210 935 500', null, null, 'Quinta da Fonte, Edif. D. Manuel I, Piso 2A, Rua dos Malhões 1, 2770-071 Paço de Arcos', 'Grupo farmacêutico e diagnóstico médico com equipas comerciais e administrativas em Oeiras.', 3),
('company', array['attendance']::text[], 'Acústica Médica (Sede)', 'Apresentar sessões de bem-estar corporativo e protocolo para colaboradores.', 'info@acusticamedica.pt', '+351 218 426 806', null, null, 'Quinta da Fonte, 2770-100 Paço de Arcos, Oeiras', 'Empresa nacional de audiologia com estrutura corporativa residente na Quinta da Fonte.', 3),
('company', array['attendance']::text[], 'Laboratório Edol', 'Bem-estar corporativo e prevenção de desconfortos músculo-esqueléticos.', 'geral@edol.pt', '+351 214 158 130', null, null, 'Rua Casal do Canas 6, 2790-204 Carnaxide, Oeiras', 'Indústria farmacêutica; documento refere mais de 150 colaboradores entre escritórios e unidade fabril.', 3),
('company', array['attendance']::text[], 'Viagens Abreu (Sede Operacional)', 'Apresentar blocos de bem-estar corporativo e protocolo para equipas.', null, '+351 214 156 000', null, 'https://www.abreu.pt', 'Edifício Central, 2795-242 Linda-a-Velha, Oeiras', 'Operadora turística com centro administrativo e atendimento em Linda-a-Velha. O PDF indica contacto via portal corporativo.', 3),
('company', array['attendance']::text[], 'ANSR — Autoridade Nacional de Segurança Rodoviária', 'Propor sessões corporativas de bem-estar para equipas administrativas.', 'mail@ansr.pt', '+351 214 220 400', null, null, 'Av. de Casal de Cabanas 1, Urb. Cabanas Golf, 2734-507 Barcarena', 'Organismo público; documento refere centenas de funcionários administrativos.', 3),
('company', array['attendance']::text[], 'IST Taguspark — Instituto Superior Técnico', 'Bem-estar para docentes, investigadores e equipas não docentes.', 'geral_taguspark@tecnico.ulisboa.pt', '+351 218 419 905', null, null, 'Av. Prof. Doutor Cavaco Silva, Taguspark, 2744-016 Porto Salvo', 'Campus universitário; documento indica mais de 150 funcionários.', 3),
('company', array['attendance']::text[], 'Taguspark — Sociedade de Promoção', 'Protocolo de bem-estar divulgado à comunidade e na newsletter interna.', 'taguspark@taguspark.pt', '+351 214 226 900', null, null, 'Av. Jacques Delors, Núcleo Central, 2740-122 Porto Salvo', 'Gestão do parque de ciência e tecnologia; potencial canal de divulgação junto das empresas residentes.', 3),
('company', array['attendance']::text[], 'Lagoas Park (Gestão e Comunidade)', 'Protocolo de bem-estar corporativo com empresas e comunidade do parque.', 'info@lagoaspark.pt', '+351 210 155 280', null, null, 'Lagoas Park, Edifícios 2/8, 2740-265 Porto Salvo', 'Parque empresarial com multinacionais e milhares de colaboradores, segundo o documento.', 3),
('company', array['attendance']::text[], 'Quinta da Fonte (Gestão de Comunidade)', 'Ação de bem-estar para empresas residentes e divulgação junto da comunidade.', 'vida@quintadafonte.com', '+351 211 607 057', null, null, 'Quinta da Fonte, 2770-100 Paço de Arcos, Oeiras', 'Administração do parque empresarial; o documento identifica um canal direto para ações de bem-estar.', 4),
('company', array['attendance']::text[], 'Cascais Ambiente (EMAC)', 'Bem-estar corporativo para equipas operacionais e técnicas.', 'geral@cascaisambiente.pt', '+351 214 604 230', null, null, 'Complexo Multisserviços, Estrada de Manique 1830, 2645-138 Alcabideche', 'Empresa municipal de ambiente; documento refere mais de 200 funcionários.', 4),
('company', array['attendance']::text[], 'DNA Cascais (Ninho de Empresas)', 'Protocolo de bem-estar para empresas e equipas da incubadora.', 'geral@dnacascais.pt', '+351 214 680 185', null, null, 'Ninho de Empresas DNA Cascais, Cruz da Popa, 2645-449 Alcabideche', 'Incubadora e polo empresarial que agrega dezenas de empresas e equipas locais.', 4),
('clinic', array['attendance']::text[], 'Physioclem Oeiras', 'Indicação mútua, cobertura de pedidos ao domicílio e horários noturnos/fins de semana.', 'info.oeiras@physioclem.pt', '+351 212 698 754', '+351 960 335 100', null, 'Rua da Quinta das Palmeiras 86, 2780-146 Oeiras', 'Clínica de fisioterapia e osteopatia.', 4),
('clinic', array['attendance']::text[], 'Osteosaúde — Osteopatia de Oeiras', 'Indicação mútua e cobertura complementar de atendimentos ao domicílio.', 'osteosaudee@gmail.com', '+351 916 274 470', '+351 916 274 470', null, 'Alameda Bonifácio Lázaro Lozano 15 1D, 2780-125 Oeiras', 'Clínica especializada no centro de Oeiras.', 4),
('clinic', array['attendance']::text[], 'Ana Moreira — Fisioterapia e Osteopatia', 'Parceria de indicação e eventual cobertura de horários/atendimentos.', 'amoreira.ft@gmail.com', '+351 968 635 436', '+351 968 635 436', null, 'Rua de Oeiras do Piauí Brasil 7B, 2780-285 Oeiras', 'Atendimento em centro de bem-estar em Oeiras com disponibilidade parcial.', 4),
('clinic', array['attendance']::text[], 'Fisioterapia Oeiras', 'Indicação mútua e cobertura de pedidos complementares ao domicílio.', 'fisioterapiaemoeiras@gmail.com', '+351 967 772 888', '+351 967 772 888', null, 'Rua José Malhoa 19, 2780-017 Oeiras', 'Clínica de reabilitação física na vila de Oeiras.', 4),
('clinic', array['attendance']::text[], 'Gabinete de Osteopatia Rui Antunes', 'Indicação mútua e cobertura de atendimentos ao domicílio.', 'ruimateus.1974@gmail.com', '+351 919 409 872', '+351 919 409 872', null, 'Praceta dos Sete Castelos, 2780-305 Oeiras', 'Consultório de osteopatia em Oeiras.', 4),
('clinic', array['attendance']::text[], 'Clínica 2Hands (Linda-a-Velha)', 'Parceria de encaminhamento mútuo e cobertura de terapia manual ao domicílio.', '2handsclinica@gmail.com', '+351 912 626 026', '+351 912 626 026', null, 'Largo Professor João Cid dos Santos 9B, 2795-104 Linda-a-Velha', 'Clínica de terapia manual e osteopatia na zona oriental de Oeiras.', 5),
('clinic', array['attendance']::text[], 'OSTEOJP Osteopatia / Fisioterapia', 'Indicação mútua e cobertura de pedidos ao domicílio ou horários alternativos.', null, '+351 214 191 810', '+351 969 472 111', 'https://osteojp.pt', 'Rua Afonso Duarte 7 / Praça Central Plaza 1-A, 2795-246 Linda-a-Velha', 'Clínica de osteopatia e fisioterapia em Linda-a-Velha. E-mail indicado via formulário do site.', 5),
('clinic', array['attendance']::text[], 'FisioMoço (Paço de Arcos)', 'Indicação mútua e cobertura de atendimentos ao domicílio.', null, '+351 928 095 777', '+351 928 095 777', 'https://fisiomoco.pt', 'Rua Manuel Inácio 8B, 2770-223 Paço de Arcos', 'Clínica em Paço de Arcos. E-mail indicado via site.', 5),
('clinic', array['attendance']::text[], 'KAI•ZEN — Wellness Hub', 'Parceria de espaço/coworking terapêutico e encaminhamento de clientes.', 'geral@kaizenoeiras.pt', null, null, 'https://kaizenoeiras.pt', 'Av. Dom João I 10A, 2780-062 Oeiras', 'Espaço de coworking terapêutico em Oeiras; WhatsApp indicado via portal.', 5),
('clinic', array['attendance']::text[], 'Equilibrato Fisioterapia e Estética', 'Indicação mútua e cobertura complementar de atendimentos.', 'info@equilibrato.pt', '+351 935 157 183', '+351 935 157 183', null, 'Praceta Belo Horizonte 41A Loja, 2645-090 Alcabideche', 'Clínica em Alcabideche, Cascais.', 5),
('clinic', array['attendance']::text[], 'GTMMI — Terapias Manuais e Medicina Integrada', 'Indicação mútua e eventual cobertura de horários/pedidos complementares.', 'geral@gtmmi.pt', '+351 214 824 044', '+351 961 392 881', null, 'Edifício Alvorada, Av. 25 de Abril 672 1D, 2750-512 Cascais', 'Gabinete no centro de Cascais.', 5),
('clinic', array['attendance']::text[], 'Sónia Martins — Osteopatia e Fisioterapia', 'Indicação mútua e cobertura complementar de atendimentos.', 'soniamartins.osteopatia@gmail.com', '+351 910 171 033', '+351 910 171 033', null, 'Av. 25 de Abril 672, Edifício Alvorada 2A, Sala 1, 2750-512 Cascais', 'Consultório de osteopatia e fisioterapia no centro de Cascais.', 5),
('clinic', array['attendance']::text[], 'Osteopath Cascais — Léon Hohn', 'Indicação mútua e cobertura para público internacional/expats.', null, '+33 6 82 51 26 10', '+33 6 82 51 26 10', 'https://osteopathcascais.com', 'Rua João Infante 104B, Cooffice 104, Unit 6, 2750-384 Cascais', 'Foco no público internacional/expats em Cascais; contacto eletrónico via site.', 5),
('clinic', array['attendance']::text[], 'Miguel Queiroz — Osteopata', 'Indicação mútua e cobertura estratégica entre Oeiras e Cascais.', null, '+351 927 333 050', '+351 927 333 050', 'https://osteopatiacascais.pt', 'Rua de Itália, Rua Quinta de São Gonçalo 1, 1.º Fracção 7, 2775-407 Carcavelos', 'Consultório em Carcavelos; contacto via site.', 5),
('pilates', array['attendance']::text[], 'Forma Pilates Oeiras', 'Troca de indicações: massagem terapêutica e recuperação muscular para alunos.', 'info@formapilatesoeiras.com', '+351 924 155 553', '+351 924 155 553', null, 'Praceta Bernardo Sassetti 8A, 2740-315 Porto Salvo', 'Localizado em Porto Salvo, junto ao Taguspark.', 6),
('pilates', array['attendance']::text[], 'Club Pilates Oeiras', 'Troca de indicações para massagem terapêutica e recuperação muscular dos alunos.', 'oeiras@clubpilates.pt', '+351 910 844 336', '+351 910 844 336', null, 'Rua Coro de Santo Amaro de Oeiras 8C, 2780-379 Oeiras', 'Estúdio de Pilates Reformer no centro de Oeiras.', 6),
('pilates', array['attendance']::text[], 'Pilates Evolution Studio', 'Troca de indicações para massagem terapêutica e recuperação muscular.', null, '+351 929 041 828', '+351 929 041 828', 'https://www.instagram.com/pilates_evolutionstudio', 'Rua A Gazeta d''Oeiras 2 Lj C, 2780-171 Oeiras', 'Pilates Clínico em Oeiras; e-mail indicado via Instagram.', 6),
('pilates', array['attendance']::text[], 'New Way Pilates e Fisioterapia', 'Troca de indicações entre Pilates, fisioterapia e recuperação muscular.', null, '+351 939 573 655', '+351 939 573 655', null, 'Rua Carlos Vieira Ramos 40B, 2780-201 Oeiras', 'Estúdio integrado de Pilates e Fisioterapia; contacto telefónico direto.', 6),
('pilates', array['attendance']::text[], 'Revamp Reformer Pilates', 'Troca de indicações para massagem terapêutica e recuperação muscular.', 'hello@revamppilates.com', '+351 912 055 751', '+351 912 055 751', null, 'Rua José Carvalho Araújo 236C, 2750-396 Cascais', 'Estúdio moderno em Cascais.', 6),
('pilates', array['attendance']::text[], 'Core Collective Cascais', 'Troca de indicações e ações para a comunidade local/internacional.', 'corecollective.cascais@gmail.com', '+351 937 228 345', '+351 937 228 345', null, 'Av. 25 de Abril 528 Loja 2, 2750-511 Cascais', 'Estúdio boutique em Cascais com forte comunidade internacional.', 6),
('pilates', array['attendance']::text[], 'Estúdio Pilates Cascais', 'Troca de indicações para massagem terapêutica e recuperação muscular.', null, '+351 924 484 964', '+351 924 484 964', 'https://estudiopilatescascais.com', 'Alameda da Guia 190B, 2750-368 Cascais', 'Pilates clássico e clínico na zona da Guia, Cascais.', 6),
('pilates', array['attendance']::text[], 'Body Work Studio Pilates Clínico', 'Troca de indicações para massagem terapêutica e recuperação muscular.', null, '+351 961 090 939', '+351 961 090 939', 'https://www.instagram.com/bodywork_studiopilates', 'Av. Nossa Senhora do Rosário 541, 2750-778 Cascais', 'Foco em Pilates Clínico; contacto indicado via Instagram.', 6),
('pilates', array['attendance']::text[], 'Prescription — Pilates Studio', 'Troca de indicações e ligação entre Cascais e Sintra.', null, '+351 926 131 822', '+351 926 131 822', 'https://prescription.pt', 'Rua Hermenegildo Pulquério 201A Loja 8, 2645-089 Alcabideche', 'Estúdio em Alcabideche; contacto via site.', 6)
) as p(category, collaboration_types, name, proposal, email, phone, whatsapp, website, address, notes, source_page)
where bu.code = '001'
on conflict (business_id, name) do nothing;
