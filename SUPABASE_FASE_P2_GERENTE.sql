-- ============================================================================
-- Fase P.2 — Nível de acesso "Gerente" + campo "Cargo".
--
-- `cargo` é só texto livre (ex: "Social Media", "Sócia") — identifica a pessoa,
-- não controla nada. Quem controla acesso continua sendo `role`, que ganha um
-- 4º valor: `gerente` — gerencia a equipe (cadastrar, editar, promover/
-- rebaixar), mas NUNCA cria nem mexe em contas `admin` — isso é travado aqui
-- no banco (não só escondido na interface), pra ninguém com acesso de gestão
-- conseguir se auto-promover ou criar um admin por fora da tela.
--
-- Pré-requisito: já ter rodado SUPABASE_FASE_P_CONTAS_EQUIPE.sql e
-- SUPABASE_FASE_P1_EQUIPE_UI.sql antes.
-- Rode isso inteiro no SQL Editor do Supabase, de uma vez.
-- ============================================================================

-- 1. Campo novo: cargo (texto livre, só exibição).
alter table public.profiles add column if not exists cargo text;

-- 2. `role` passa a aceitar 'gerente' também.
alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles add constraint profiles_role_check check (role in ('admin','vendedor','gerente','membro'));

-- 3. RLS: admin OU gerente conseguem ver a equipe inteira (antes só admin).
drop policy if exists "profiles_select_own_or_admin" on public.profiles;
create policy "profiles_select_own_or_admin" on public.profiles for select to authenticated using (
  auth.uid() = id or current_user_role() in ('admin','gerente')
);

-- 4. RLS: admin pode tudo. Gerente só pode mexer em linhas que NÃO são admin
--    (USING) e nunca pode deixar uma linha como admin (WITH CHECK) — trava
--    dupla: não dá pra editar um admin existente, nem promover ninguém a admin.
drop policy if exists "profiles_update_admin_only" on public.profiles;
create policy "profiles_update_admin_or_gerente" on public.profiles for update to authenticated using (
  current_user_role() = 'admin' or (current_user_role() = 'gerente' and role <> 'admin')
) with check (
  current_user_role() = 'admin' or (current_user_role() = 'gerente' and role <> 'admin')
);
