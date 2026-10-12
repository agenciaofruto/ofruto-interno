-- ============================================================================
-- Minha falha: mandei o SQL de fotos pra você antes de terminar de editá-lo,
-- então a parte que libera os tipos de campo "image"/"url" ficou de fora do
-- que você rodou. O bucket e as policies de Storage já estão criados (não
-- precisa mexer nisso de novo) — falta só esta parte:
-- ============================================================================

ALTER TABLE fields DROP CONSTRAINT IF EXISTS fields_field_type_check;
ALTER TABLE fields ADD CONSTRAINT fields_field_type_check CHECK (field_type IN (
  'text', 'number', 'date', 'checkbox', 'email', 'tel', 'moeda',
  'select', 'multi-select', 'relationship', 'textarea', 'image', 'url'
));
