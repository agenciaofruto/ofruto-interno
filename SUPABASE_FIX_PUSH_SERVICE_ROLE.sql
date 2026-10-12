-- ============================================================================
-- Correção: a Edge Function send-push usa a service_role key (ela precisa ver
-- todas as assinaturas, não só as do usuário que disparou a chamada), mas a
-- tabela push_subscriptions nunca recebeu GRANT pro papel "service_role" —
-- mesmo bug que já tinha acontecido antes com a tabela `propostas`.
--
-- Rode isso no SQL Editor do Supabase.
-- ============================================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON public.push_subscriptions TO service_role;
