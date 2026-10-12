-- Central oFruto Schema
-- Execute isso no Supabase SQL Editor
-- https://app.supabase.com/project/[seu-project-id]/sql/new

-- ============================================================================
-- 1. MODULES (Define estrutura da plataforma)
-- ============================================================================
CREATE TABLE modules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  icon TEXT,
  section TEXT NOT NULL CHECK (section IN ('Núcleo', 'Negócio')),
  description TEXT,
  type TEXT NOT NULL DEFAULT 'user' CHECK (type IN ('core', 'user')),
  "order" INTEGER DEFAULT 0,
  hidden BOOLEAN DEFAULT FALSE,
  created_by UUID,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(name, section)
);

-- ============================================================================
-- 2. FIELDS (Define campos em cada módulo)
-- ============================================================================
CREATE TABLE fields (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  module_id UUID NOT NULL REFERENCES modules(id) ON DELETE CASCADE,
  field_name TEXT NOT NULL,
  field_type TEXT NOT NULL CHECK (field_type IN (
    'text', 'number', 'date', 'checkbox',
    'email', 'tel', 'moeda',
    'select', 'multi-select', 'relationship'
  )),
  field_options JSONB, -- {label, value, color} array para select/multi-select
  is_required BOOLEAN DEFAULT FALSE,
  is_hidden BOOLEAN DEFAULT FALSE,
  "order" INTEGER DEFAULT 0,
  created_by UUID,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(module_id, field_name)
);

-- ============================================================================
-- 3. RECORDS (Dados reais editáveis)
-- ============================================================================
CREATE TABLE records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  module_id UUID NOT NULL REFERENCES modules(id) ON DELETE CASCADE,
  data JSONB NOT NULL DEFAULT '{}', -- {field_name: value, ...}
  status_id UUID,
  created_by UUID,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_by UUID
);

CREATE INDEX idx_records_module_id ON records(module_id);
CREATE INDEX idx_records_created_at ON records(created_at);

-- ============================================================================
-- 4. STATUSES (Status customizáveis por módulo)
-- ============================================================================
CREATE TABLE statuses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  module_id UUID NOT NULL REFERENCES modules(id) ON DELETE CASCADE,
  status_name TEXT NOT NULL,
  status_color TEXT, -- hex color ou css color name
  status_icon TEXT,
  "order" INTEGER DEFAULT 0,
  created_by UUID,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(module_id, status_name)
);

-- ============================================================================
-- 5. RELATIONSHIPS (Definições de relação entre módulos)
-- ============================================================================
CREATE TABLE relationships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_module_id UUID NOT NULL REFERENCES modules(id) ON DELETE CASCADE,
  to_module_id UUID NOT NULL REFERENCES modules(id) ON DELETE CASCADE,
  relationship_type TEXT NOT NULL CHECK (relationship_type IN ('1:1', '1:N', 'N:N')),
  from_field_name TEXT, -- campo na tabela "from" que armazena a relação
  to_field_name TEXT, -- campo na tabela "to" que é referenciado
  created_by UUID,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(from_module_id, to_module_id, from_field_name)
);

-- ============================================================================
-- 6. PERMISSIONS_ROLES (Permissões por role)
-- ============================================================================
CREATE TABLE permissions_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role TEXT NOT NULL CHECK (role IN ('admin', 'gerente', 'sócio')),
  module_id UUID NOT NULL REFERENCES modules(id) ON DELETE CASCADE,
  field_id UUID, -- NULL = permissão em todo o módulo
  can_view BOOLEAN DEFAULT TRUE,
  can_create BOOLEAN DEFAULT FALSE,
  can_edit BOOLEAN DEFAULT FALSE,
  can_delete BOOLEAN DEFAULT FALSE,
  created_by UUID,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(role, module_id, field_id)
);

CREATE INDEX idx_permissions_roles_role_module ON permissions_roles(role, module_id);

-- ============================================================================
-- 7. PERMISSIONS_RECORDS (Permissões granulares por registro — v2)
-- ============================================================================
CREATE TABLE permissions_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role TEXT NOT NULL CHECK (role IN ('admin', 'gerente', 'sócio')),
  record_id UUID NOT NULL REFERENCES records(id) ON DELETE CASCADE,
  field_id UUID REFERENCES fields(id) ON DELETE CASCADE,
  access_level TEXT NOT NULL DEFAULT 'none' CHECK (access_level IN ('view', 'edit', 'none')),
  created_by UUID,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(role, record_id, field_id)
);

-- ============================================================================
-- 8. METADATA (Config protegida: serviços, metodologia, filtros)
-- ============================================================================
CREATE TABLE metadata (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  section TEXT NOT NULL, -- 'servicos', 'metodologia', 'filtros'
  key TEXT NOT NULL,
  data JSONB NOT NULL,
  created_by UUID,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(section, key)
);

-- ============================================================================
-- RLS POLICIES (Row Level Security)
-- ============================================================================

-- Modules: todos podem ver, admin pode editar
ALTER TABLE modules ENABLE ROW LEVEL SECURITY;
CREATE POLICY "modules_select" ON modules FOR SELECT USING (true);
CREATE POLICY "modules_insert" ON modules FOR INSERT WITH CHECK (
  auth.jwt() ->> 'role' = 'admin'
);
CREATE POLICY "modules_update" ON modules FOR UPDATE USING (
  auth.jwt() ->> 'role' = 'admin'
) WITH CHECK (
  auth.jwt() ->> 'role' = 'admin'
);
CREATE POLICY "modules_delete" ON modules FOR DELETE USING (
  auth.jwt() ->> 'role' = 'admin'
);

-- Fields: todos podem ver, admin pode editar
ALTER TABLE fields ENABLE ROW LEVEL SECURITY;
CREATE POLICY "fields_select" ON fields FOR SELECT USING (true);
CREATE POLICY "fields_insert" ON fields FOR INSERT WITH CHECK (
  auth.jwt() ->> 'role' = 'admin'
);
CREATE POLICY "fields_update" ON fields FOR UPDATE USING (
  auth.jwt() ->> 'role' = 'admin'
) WITH CHECK (
  auth.jwt() ->> 'role' = 'admin'
);
CREATE POLICY "fields_delete" ON fields FOR DELETE USING (
  auth.jwt() ->> 'role' = 'admin'
);

-- Records: permissões via permissions_roles
ALTER TABLE records ENABLE ROW LEVEL SECURITY;
CREATE POLICY "records_select" ON records FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM permissions_roles pr
    WHERE pr.module_id = records.module_id
    AND pr.role = auth.jwt() ->> 'role'
    AND pr.can_view = true
  )
);
CREATE POLICY "records_insert" ON records FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM permissions_roles pr
    WHERE pr.module_id = records.module_id
    AND pr.role = auth.jwt() ->> 'role'
    AND pr.can_create = true
  )
);
CREATE POLICY "records_update" ON records FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM permissions_roles pr
    WHERE pr.module_id = records.module_id
    AND pr.role = auth.jwt() ->> 'role'
    AND pr.can_edit = true
  )
) WITH CHECK (
  EXISTS (
    SELECT 1 FROM permissions_roles pr
    WHERE pr.module_id = records.module_id
    AND pr.role = auth.jwt() ->> 'role'
    AND pr.can_edit = true
  )
);
CREATE POLICY "records_delete" ON records FOR DELETE USING (
  EXISTS (
    SELECT 1 FROM permissions_roles pr
    WHERE pr.module_id = records.module_id
    AND pr.role = auth.jwt() ->> 'role'
    AND pr.can_delete = true
  )
);

-- Statuses: todos podem ver, admin pode editar
ALTER TABLE statuses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "statuses_select" ON statuses FOR SELECT USING (true);
CREATE POLICY "statuses_insert" ON statuses FOR INSERT WITH CHECK (
  auth.jwt() ->> 'role' = 'admin'
);
CREATE POLICY "statuses_update" ON statuses FOR UPDATE USING (
  auth.jwt() ->> 'role' = 'admin'
) WITH CHECK (
  auth.jwt() ->> 'role' = 'admin'
);
CREATE POLICY "statuses_delete" ON statuses FOR DELETE USING (
  auth.jwt() ->> 'role' = 'admin'
);

-- Relationships: todos podem ver, admin pode editar
ALTER TABLE relationships ENABLE ROW LEVEL SECURITY;
CREATE POLICY "relationships_select" ON relationships FOR SELECT USING (true);
CREATE POLICY "relationships_insert" ON relationships FOR INSERT WITH CHECK (
  auth.jwt() ->> 'role' = 'admin'
);
CREATE POLICY "relationships_update" ON relationships FOR UPDATE USING (
  auth.jwt() ->> 'role' = 'admin'
) WITH CHECK (
  auth.jwt() ->> 'role' = 'admin'
);
CREATE POLICY "relationships_delete" ON relationships FOR DELETE USING (
  auth.jwt() ->> 'role' = 'admin'
);

-- Permissions_roles: admin pode editar
ALTER TABLE permissions_roles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "permissions_roles_select" ON permissions_roles FOR SELECT USING (
  auth.jwt() ->> 'role' = 'admin'
);
CREATE POLICY "permissions_roles_insert" ON permissions_roles FOR INSERT WITH CHECK (
  auth.jwt() ->> 'role' = 'admin'
);
CREATE POLICY "permissions_roles_update" ON permissions_roles FOR UPDATE USING (
  auth.jwt() ->> 'role' = 'admin'
) WITH CHECK (
  auth.jwt() ->> 'role' = 'admin'
);
CREATE POLICY "permissions_roles_delete" ON permissions_roles FOR DELETE USING (
  auth.jwt() ->> 'role' = 'admin'
);

-- Metadata: todos podem ver, admin pode editar
ALTER TABLE metadata ENABLE ROW LEVEL SECURITY;
CREATE POLICY "metadata_select" ON metadata FOR SELECT USING (true);
CREATE POLICY "metadata_insert" ON metadata FOR INSERT WITH CHECK (
  auth.jwt() ->> 'role' = 'admin'
);
CREATE POLICY "metadata_update" ON metadata FOR UPDATE USING (
  auth.jwt() ->> 'role' = 'admin'
) WITH CHECK (
  auth.jwt() ->> 'role' = 'admin'
);

-- ============================================================================
-- SEED DATA (Seed inicial com estrutura básica)
-- ============================================================================

-- Módulos padrão (Núcleo)
INSERT INTO modules (name, icon, section, description, type, "order")
VALUES
  ('Quem Somos', '👥', 'Núcleo', 'História, propósito, missão, valores', 'core', 1),
  ('Equipe', '👨‍💼', 'Núcleo', 'Sócios, colaboradores, funções', 'core', 2),
  ('Cultura', '🎯', 'Núcleo', 'Princípios, rituais, diretrizes', 'core', 3),
  ('Marca', '🎨', 'Núcleo', 'Identidade, tom de voz, materiais', 'core', 4);

-- Módulos padrão (Negócio)
INSERT INTO modules (name, icon, section, description, type, "order")
VALUES
  ('Clientes', '🏢', 'Negócio', 'Entidades de negócio, relacionamentos', 'core', 1),
  ('Serviços', '⚙️', 'Negócio', 'Produtos/soluções comerciais', 'core', 2),
  ('Contratos', '📋', 'Negócio', 'Relações comerciais, condições', 'core', 3),
  ('Propostas', '💼', 'Negócio', 'Propostas comerciais', 'core', 4);

-- Inserir dados de metadata (serviços, metodologia, filtros atuais)
-- Isso será feito depois, quando migrar os dados do JSON atual
