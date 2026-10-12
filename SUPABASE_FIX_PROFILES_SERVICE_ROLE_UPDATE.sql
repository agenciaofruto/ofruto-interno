-- ============================================================================
-- Correção: faltava GRANT UPDATE em profiles em dois lugares — mesma classe de
-- bug de sempre, RLS e GRANT são coisas diferentes, os dois precisam existir:
-- 1. service_role: a Edge Function admin-create-team-member usa isso pra
--    promover a função de um membro recém-criado (só tinha SELECT, da correção
--    anterior do send-push).
-- 2. authenticated: o dropdown de trocar função na tela Equipe roda como você
--    mesmo (authenticated), não como service_role — a RLS já permitia (Fase
--    P.1), mas faltava o GRANT.
--
-- Rode isso no SQL Editor do Supabase.
-- ============================================================================

GRANT SELECT, INSERT, UPDATE ON public.profiles TO service_role;
GRANT UPDATE ON public.profiles TO authenticated;
