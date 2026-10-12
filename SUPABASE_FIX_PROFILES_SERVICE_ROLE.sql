-- ============================================================================
-- Correção: a Edge Function send-push usa a service_role key pra cruzar
-- push_subscriptions com profiles (decidir quem recebe cada notificação por
-- função), mas a tabela profiles nunca recebeu GRANT pro papel "service_role"
-- — mesmo bug que já tinha acontecido antes com push_subscriptions (Fase N).
--
-- Rode isso no SQL Editor do Supabase.
-- ============================================================================

GRANT SELECT ON public.profiles TO service_role;
