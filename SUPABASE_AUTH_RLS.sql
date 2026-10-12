-- ============================================================================
-- Migração: exigir login (Supabase Auth) para acessar os dados internos.
-- Rode isso no SQL Editor do Supabase DEPOIS de criar sua conta em
-- Authentication → Users (veja instruções no chat).
--
-- O que faz:
--   1. Remove TODAS as policies existentes das tabelas internas (modules, fields,
--      records, statuses, relationships, permissions_roles, permissions_records,
--      metadata) — não importa o nome que tenham hoje.
--   2. Recria policies que só permitem acesso a usuários autenticados (role
--      "authenticated"), removendo o acesso público (anon) que existia até agora.
--   3. Revoga os GRANTs de anon nessas tabelas e concede a authenticated.
--
-- Nota: a tabela `clientes` (dedicada, do início do projeto) não entra aqui —
-- o app hoje guarda clientes dentro de `records` (module_id do módulo "Clientes"),
-- já coberto pela policy de `records` abaixo. Se essa tabela antiga ainda existir
-- no seu banco, está órfã e pode ser removida quando quiser (fora do escopo aqui).
--
-- IMPORTANTE: a tabela `propostas` NÃO é tocada aqui de propósito — o link
-- público de proposta (proposta.html) precisa continuar legível sem login.
-- Se quiser reforçar também as escritas de `propostas` (criar/editar/excluir
-- só por quem está logado, mantendo a leitura pública), me avise que preparo
-- uma migração separada e específica pra ela, testando com cuidado o link
-- público antes e depois.
-- ============================================================================

DO $$
DECLARE
  pol RECORD;
  alvo TEXT[] := ARRAY['modules','fields','records','statuses','relationships',
                        'permissions_roles','permissions_records','metadata'];
BEGIN
  FOR pol IN
    SELECT schemaname, tablename, policyname
    FROM pg_policies
    WHERE schemaname = 'public' AND tablename = ANY(alvo)
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', pol.policyname, pol.schemaname, pol.tablename);
  END LOOP;
END $$;

-- Recria: só usuário logado (authenticated) pode ler/criar/editar/excluir.
CREATE POLICY "authenticated_all" ON modules FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all" ON fields FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all" ON records FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all" ON statuses FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all" ON relationships FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all" ON permissions_roles FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all" ON permissions_records FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all" ON metadata FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Sem GRANT, RLS nem chega a ser avaliada — precisa dos dois.
REVOKE ALL ON modules, fields, records, statuses, relationships,
  permissions_roles, permissions_records, metadata FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON modules, fields, records, statuses, relationships,
  permissions_roles, permissions_records, metadata TO authenticated;
