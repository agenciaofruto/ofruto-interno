-- ============================================================================
-- Fase P.1 — Gestão de equipe pela interface: adiciona e-mail em `profiles`
-- (pra não precisar consultar auth.users, que o frontend não enxerga) e as
-- policies de RLS que deixam um admin ver a equipe inteira e trocar a função
-- de qualquer um pelo dropdown, direto na tela — sem precisar de SQL Editor
-- pra isso no dia a dia. Criar conta nova continua exigindo a Edge Function
-- `admin-create-team-member` (só o servidor pode criar login de verdade).
--
-- Pré-requisito: já ter rodado SUPABASE_FASE_P_CONTAS_EQUIPE.sql antes.
-- Rode isso inteiro no SQL Editor do Supabase, de uma vez.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Coluna nova: email guardado direto em profiles, pra lista de equipe não
--    depender de consultar auth.users (schema que o frontend não enxerga).
-- ----------------------------------------------------------------------------
alter table public.profiles add column if not exists email text;

-- Backfill da sua própria linha (único registro que já existe até agora).
update public.profiles p set email = u.email
from auth.users u
where u.id = p.id and p.email is null;

-- ----------------------------------------------------------------------------
-- 2. Trigger atualizado: toda conta nova já grava o e-mail junto com o role
--    padrão 'membro' (substitui a versão da Fase P, que só gravava o id).
-- ----------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, role) values (new.id, new.email, 'membro')
  on conflict (id) do nothing;
  return new;
end;
$$;

-- ----------------------------------------------------------------------------
-- 3. RLS nova: admin lê a equipe inteira e troca o role de qualquer um pelo
--    dropdown (update comum, sem precisar de Edge Function pra isso).
--    Ninguém ganha insert/delete via client — criar conta continua só pela
--    Edge Function (service_role) ou pelo trigger acima.
-- ----------------------------------------------------------------------------
drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own_or_admin" on public.profiles for select to authenticated using (
  auth.uid() = id or current_user_role() = 'admin'
);

create policy "profiles_update_admin_only" on public.profiles for update to authenticated using (
  current_user_role() = 'admin'
) with check (
  current_user_role() = 'admin'
);
