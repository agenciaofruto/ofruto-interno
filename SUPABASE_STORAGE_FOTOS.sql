-- ============================================================================
-- Cria o espaço de armazenamento (bucket) pras fotos de Pessoas e Clientes,
-- e libera dois novos tipos de campo no motor genérico: "image" (foto, com
-- upload) e "url" (link, ex: contrato). Rode no SQL Editor do Supabase.
--
-- O que faz:
--   1. Cria o bucket "photos" (leitura pública — qualquer um com o link vê a
--      foto, igual qualquer avatar comum; upload/edição/exclusão só por quem
--      está logado).
--   2. Cria as 4 policies de acesso (select/insert/update/delete) na tabela
--      interna do Storage (storage.objects), filtradas pelo bucket "photos".
--   3. Adiciona 'image' e 'url' aos tipos de campo permitidos em `fields`
--      (mesmo padrão usado antes pra liberar 'textarea', na Fase E).
-- ============================================================================

ALTER TABLE fields DROP CONSTRAINT IF EXISTS fields_field_type_check;
ALTER TABLE fields ADD CONSTRAINT fields_field_type_check CHECK (field_type IN (
  'text', 'number', 'date', 'checkbox', 'email', 'tel', 'moeda',
  'select', 'multi-select', 'relationship', 'textarea', 'image', 'url'
));

insert into storage.buckets (id, name, public)
values ('photos', 'photos', true)
on conflict (id) do nothing;

create policy "Fotos: leitura pública"
on storage.objects for select
to public
using (bucket_id = 'photos');

create policy "Fotos: upload por usuários logados"
on storage.objects for insert
to authenticated
with check (bucket_id = 'photos');

create policy "Fotos: atualizar por usuários logados"
on storage.objects for update
to authenticated
using (bucket_id = 'photos');

create policy "Fotos: excluir por usuários logados"
on storage.objects for delete
to authenticated
using (bucket_id = 'photos');
