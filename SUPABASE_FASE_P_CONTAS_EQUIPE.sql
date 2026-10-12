-- ============================================================================
-- Fase P — Contas de equipe: cada login tem uma função (role) de verdade,
-- guardada em `profiles`, e o banco passa a aplicar essa função nas 4 tabelas
-- do motor genérico (modules/fields/records/statuses) — não é só esconder
-- item de menu, é bloquear de verdade mesmo via console/API direta.
--
-- Rode isso inteiro no SQL Editor do Supabase, de uma vez.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Tabela `profiles` — uma linha por login, com a função de verdade.
--    `admin` enxerga tudo. `vendedor` é a função usada no exemplo (CRM +
--    Propostas + Serviços). `membro` é o padrão de segurança: qualquer login
--    sem função configurada cai no mínimo de acesso, não no máximo.
-- ----------------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'membro' check (role in ('admin','vendedor','membro')),
  created_at timestamptz default now()
);
alter table public.profiles enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own" on public.profiles for select to authenticated using (auth.uid() = id);
-- Sem policy de insert/update/delete pra "authenticated" de propósito — função só
-- muda via SQL Editor (mesmo padrão já usado pra criar a própria conta: "contas
-- são criadas manualmente", ver comentário em index.html).
grant select on public.profiles to authenticated;

-- ----------------------------------------------------------------------------
-- 2. current_user_role() — lê a própria função sem risco de recursão de RLS
--    (security definer ignora a RLS de `profiles` só dentro desta função).
--    Usada pelas policies abaixo.
-- ----------------------------------------------------------------------------
create or replace function public.current_user_role()
returns text
language sql
security definer
stable
set search_path = public
as $$
  select role from public.profiles where id = auth.uid();
$$;

-- ----------------------------------------------------------------------------
-- 3. Trigger: toda conta nova (Authentication → Users) já ganha uma linha em
--    `profiles` sozinha (role 'membro' por padrão) — você só precisa rodar um
--    UPDATE pra promover, em vez de duas inserções manuais. Não retroage pra
--    contas que já existem (a sua precisa da linha manual na seção 6).
-- ----------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, role) values (new.id, 'membro')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ----------------------------------------------------------------------------
-- 4. Coluna nova em `modules`: quais funções (além de admin, que sempre pode)
--    têm acesso a esse módulo. NULL = só admin (padrão restritivo).
-- ----------------------------------------------------------------------------
alter table public.modules add column if not exists allowed_roles text[];

-- Funis de CRM (kind='funil') ficam abertos pra vendedor — cobre o funil "CRM"
-- que já existe e qualquer outro criado manualmente antes desta migração.
-- Funis criados depois disso já nascem assim via criarFunil() no index.html.
update public.modules set allowed_roles = array['vendedor'] where kind = 'funil';

-- ----------------------------------------------------------------------------
-- 5. Policies novas pra modules/fields/records/statuses — substituem as
--    "authenticated_all USING(true)" que existiam (criadas em SUPABASE_AUTH_RLS.sql).
--    Duas granularidades: ESTRUTURA (modules/fields — criar/editar/excluir
--    módulo ou campo) é admin-only, exceto criar funil, que fica liberado pra
--    qualquer autenticado porque o botão "+ Criar funil" já é usado por quem
--    só tem acesso ao CRM. DADO (records/statuses) segue allowed_roles do
--    módulo — inclui `statuses` porque "Gerenciar fases" já aparece direto
--    na tela do funil, não só no Admin.
-- ----------------------------------------------------------------------------
drop policy if exists "authenticated_all" on public.modules;
drop policy if exists "authenticated_all" on public.fields;
drop policy if exists "authenticated_all" on public.records;
drop policy if exists "authenticated_all" on public.statuses;

-- modules
create policy "role_select_modules" on public.modules for select to authenticated using (
  current_user_role() = 'admin'
  or (allowed_roles is not null and current_user_role() = any(allowed_roles))
);
create policy "role_insert_modules" on public.modules for insert to authenticated with check (
  current_user_role() = 'admin' or kind = 'funil'
);
create policy "role_update_modules" on public.modules for update to authenticated using (
  current_user_role() = 'admin'
) with check (
  current_user_role() = 'admin'
);
create policy "role_delete_modules" on public.modules for delete to authenticated using (
  current_user_role() = 'admin'
);

-- fields (estrutura — sempre admin-only, nenhuma tela de vendedor mexe aqui)
create policy "role_select_fields" on public.fields for select to authenticated using (
  current_user_role() = 'admin'
  or exists (
    select 1 from public.modules m where m.id = fields.module_id
    and m.allowed_roles is not null and current_user_role() = any(m.allowed_roles)
  )
);
create policy "role_insert_fields" on public.fields for insert to authenticated with check (
  current_user_role() = 'admin'
);
create policy "role_update_fields" on public.fields for update to authenticated using (
  current_user_role() = 'admin'
) with check (
  current_user_role() = 'admin'
);
create policy "role_delete_fields" on public.fields for delete to authenticated using (
  current_user_role() = 'admin'
);

-- records (dado real — leitura e escrita seguem allowed_roles do módulo)
create policy "role_select_records" on public.records for select to authenticated using (
  current_user_role() = 'admin'
  or exists (
    select 1 from public.modules m where m.id = records.module_id
    and m.allowed_roles is not null and current_user_role() = any(m.allowed_roles)
  )
);
create policy "role_insert_records" on public.records for insert to authenticated with check (
  current_user_role() = 'admin'
  or exists (
    select 1 from public.modules m where m.id = records.module_id
    and m.allowed_roles is not null and current_user_role() = any(m.allowed_roles)
  )
);
create policy "role_update_records" on public.records for update to authenticated using (
  current_user_role() = 'admin'
  or exists (
    select 1 from public.modules m where m.id = records.module_id
    and m.allowed_roles is not null and current_user_role() = any(m.allowed_roles)
  )
) with check (
  current_user_role() = 'admin'
  or exists (
    select 1 from public.modules m where m.id = records.module_id
    and m.allowed_roles is not null and current_user_role() = any(m.allowed_roles)
  )
);
create policy "role_delete_records" on public.records for delete to authenticated using (
  current_user_role() = 'admin'
  or exists (
    select 1 from public.modules m where m.id = records.module_id
    and m.allowed_roles is not null and current_user_role() = any(m.allowed_roles)
  )
);

-- statuses (fases de um funil — mesma regra de records, não só admin)
create policy "role_select_statuses" on public.statuses for select to authenticated using (
  current_user_role() = 'admin'
  or exists (
    select 1 from public.modules m where m.id = statuses.module_id
    and m.allowed_roles is not null and current_user_role() = any(m.allowed_roles)
  )
);
create policy "role_insert_statuses" on public.statuses for insert to authenticated with check (
  current_user_role() = 'admin'
  or exists (
    select 1 from public.modules m where m.id = statuses.module_id
    and m.allowed_roles is not null and current_user_role() = any(m.allowed_roles)
  )
);
create policy "role_update_statuses" on public.statuses for update to authenticated using (
  current_user_role() = 'admin'
  or exists (
    select 1 from public.modules m where m.id = statuses.module_id
    and m.allowed_roles is not null and current_user_role() = any(m.allowed_roles)
  )
) with check (
  current_user_role() = 'admin'
  or exists (
    select 1 from public.modules m where m.id = statuses.module_id
    and m.allowed_roles is not null and current_user_role() = any(m.allowed_roles)
  )
);
create policy "role_delete_statuses" on public.statuses for delete to authenticated using (
  current_user_role() = 'admin'
  or exists (
    select 1 from public.modules m where m.id = statuses.module_id
    and m.allowed_roles is not null and current_user_role() = any(m.allowed_roles)
  )
);

-- ----------------------------------------------------------------------------
-- 6. SUA PRÓPRIA CONTA — PASSO OBRIGATÓRIO, NÃO PULE ESTE.
--    O trigger da seção 3 só vale pra contas criadas DEPOIS desta migração — a
--    sua já existe, precisa da linha manual uma única vez. A partir do momento
--    em que você rodar este arquivo, qualquer login sem linha em `profiles`
--    (inclusive o seu, se pular este passo) vira 'membro' — o mais restrito —
--    tanto na interface quanto no banco. Pra não acontecer isso com VOCÊ:
--
--    Já preenchi abaixo com o e-mail que uso pra te identificar nesta conversa
--    (davimourx@gmail.com). Confirme que é o MESMO e-mail que você usa pra
--    logar na Central (Google ou e-mail/senha) antes de rodar — se for outro,
--    troque pelo certo. Isso roda sozinho junto com o resto do arquivo, não
--    precisa ir copiar UID em lugar nenhum.
-- ----------------------------------------------------------------------------
insert into public.profiles (id, role)
select id, 'admin' from auth.users where email = 'davimourx@gmail.com'
on conflict (id) do update set role = 'admin';

-- Confira que funcionou (deve devolver 1 linha, com role='admin'):
-- select u.email, p.role from public.profiles p join auth.users u on u.id = p.id;
