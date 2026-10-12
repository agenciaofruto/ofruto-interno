-- ============================================================================
-- CORREÇÃO URGENTE: a tabela `propostas` nunca recebeu GRANT pro papel
-- "authenticated". Antes de existir login, toda requisição (inclusive suas,
-- dentro da Central) usava o papel "anon" — por isso funcionava. Agora que
-- você está logado, suas requisições passam a usar "authenticated", e como
-- essa tabela só tinha permissão pra "anon", você ficou sem conseguir
-- ler/criar/editar propostas dentro da Central (o link público continua
-- funcionando normalmente, porque esse é acessado sem login, como "anon").
--
-- Rode isso no SQL Editor do Supabase agora.
-- ============================================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON public.propostas TO authenticated;
