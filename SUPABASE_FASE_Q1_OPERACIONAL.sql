-- ============================================================================
-- Fase Q1 — Operacional mínimo: libera o novo tipo de módulo "conteudo" (pro
-- quadro de produção de Conteúdos, com etapas configuráveis igual os funis de
-- CRM) e adiciona a trava de "só o responsável edita/exclui" nos registros de
-- Conteúdos — admin e gerente sempre podem; qualquer outra pessoa com acesso
-- ao operacional consegue VER o card de todo mundo (isso não muda), mas só
-- edita/exclui o que é atribuído a ela mesma.
--
-- Pré-requisito: já ter rodado as SQLs anteriores da Fase P (P, P.1, P.2).
-- Rode isso inteiro no SQL Editor do Supabase, de uma vez.
-- ============================================================================

-- 1. `modules.kind` passa a aceitar 'conteudo' também (antes só 'content'/'funil').
alter table public.modules drop constraint if exists modules_kind_check;
alter table public.modules add constraint modules_kind_check check (kind in ('content','funil','conteudo'));

-- 2. Trava de dono: só vale pra registros de módulos kind='conteudo'. Pra
--    qualquer outro módulo, a condição "not exists (...)" já é verdadeira e a
--    política não restringe nada (continua valendo só a regra normal de
--    allowed_roles da Fase P3). RESTRICTIVE = some ao resultado das políticas
--    permissivas existentes, não substitui — por isso dá pra empilhar aqui.
drop policy if exists "role_restrict_update_conteudo_dono" on public.records;
create policy "role_restrict_update_conteudo_dono" on public.records as restrictive for update to authenticated using (
  current_user_role() in ('admin','gerente')
  or not exists (select 1 from public.modules m where m.id = records.module_id and m.kind = 'conteudo')
  or (data->>'responsavel') = auth.uid()::text
) with check (
  current_user_role() in ('admin','gerente')
  or not exists (select 1 from public.modules m where m.id = records.module_id and m.kind = 'conteudo')
  or (data->>'responsavel') = auth.uid()::text
);

drop policy if exists "role_restrict_delete_conteudo_dono" on public.records;
create policy "role_restrict_delete_conteudo_dono" on public.records as restrictive for delete to authenticated using (
  current_user_role() in ('admin','gerente')
  or not exists (select 1 from public.modules m where m.id = records.module_id and m.kind = 'conteudo')
  or (data->>'responsavel') = auth.uid()::text
);
