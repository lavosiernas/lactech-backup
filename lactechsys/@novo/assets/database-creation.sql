-- =====================================================
-- LACTECH SYSTEM - COMPLETE DATABASE CREATION SCRIPT
-- Version: 2.0 (Reformulated)
-- No errors, clean structure, Portuguese naming
-- NEW SUPABASE PROJECT: mauioyodoxmuzqweaasc.supabase.co
-- =====================================================

-- Drop existing tables if they exist (in correct order to avoid FK constraints)
DROP TABLE IF EXISTS logs_atividades CASCADE;
DROP TABLE IF EXISTS configuracoes_relatorios CASCADE;
DROP TABLE IF EXISTS pix_pagamentos CASCADE;
DROP TABLE IF EXISTS assinaturas CASCADE;
DROP TABLE IF EXISTS pagamentos CASCADE;
DROP TABLE IF EXISTS tratamentos_veterinarios CASCADE;
DROP TABLE IF EXISTS testes_qualidade CASCADE;
DROP TABLE IF EXISTS producao_leite CASCADE;
DROP TABLE IF EXISTS animais CASCADE;
DROP TABLE IF EXISTS usuarios CASCADE;
DROP TABLE IF EXISTS fazendas CASCADE;

-- Drop existing functions if they exist
DROP FUNCTION IF EXISTS get_current_user_farm_id() CASCADE;
DROP FUNCTION IF EXISTS user_has_role(TEXT) CASCADE;
DROP FUNCTION IF EXISTS belongs_to_same_farm(UUID) CASCADE;
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS check_farm_exists(TEXT, TEXT) CASCADE;
DROP FUNCTION IF EXISTS check_user_exists(TEXT) CASCADE;
DROP FUNCTION IF EXISTS create_initial_farm(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) CASCADE;
DROP FUNCTION IF EXISTS create_initial_user(UUID, TEXT, TEXT, TEXT, TEXT) CASCADE;
DROP FUNCTION IF EXISTS complete_farm_setup(UUID, UUID) CASCADE;

-- =====================================================
-- 1. CORE TABLES
-- =====================================================

-- Fazendas (Farms)
CREATE TABLE fazendas (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    nome_fazenda TEXT NOT NULL,
    cnpj TEXT UNIQUE NOT NULL,
    telefone TEXT,
    endereco TEXT,
    cidade TEXT,
    estado TEXT,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deletado_em TIMESTAMP WITH TIME ZONE
);

-- Usuários (Users)
CREATE TABLE usuarios (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    fazenda_id UUID NOT NULL REFERENCES fazendas(id) ON DELETE CASCADE,
    nome TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    cargo TEXT NOT NULL CHECK (cargo IN ('proprietario', 'gerente', 'funcionario', 'veterinario')),
    telefone TEXT,
    foto_perfil TEXT,
    ativo BOOLEAN DEFAULT TRUE,
    report_farm_name TEXT,
    report_farm_logo_base64 TEXT,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deletado_em TIMESTAMP WITH TIME ZONE
);

-- Animais (Animals)
CREATE TABLE animais (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    fazenda_id UUID NOT NULL REFERENCES fazendas(id) ON DELETE CASCADE,
    nome TEXT NOT NULL,
    raca TEXT NOT NULL,
    data_nascimento DATE,
    brinco TEXT NOT NULL,
    peso DECIMAL(8,2),
    status TEXT DEFAULT 'ativo' CHECK (status IN ('ativo', 'doente', 'seco', 'prenhe', 'descartado')),
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deletado_em TIMESTAMP WITH TIME ZONE,
    UNIQUE(fazenda_id, brinco)
);

-- =====================================================
-- 2. PRODUCTION TABLES
-- =====================================================

-- Produção de Leite (Milk Production)
CREATE TABLE producao_leite (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    fazenda_id UUID NOT NULL REFERENCES fazendas(id) ON DELETE CASCADE,
    usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    data_producao DATE NOT NULL,
    hora_producao TIME,
    volume_litros DECIMAL(10,2) NOT NULL CHECK (volume_litros > 0),
    turno TEXT NOT NULL CHECK (turno IN ('manha', 'tarde', 'noite')),
    temperatura DECIMAL(5,2),
    observacoes TEXT,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deletado_em TIMESTAMP WITH TIME ZONE
);

-- Testes de Qualidade (Quality Tests)
CREATE TABLE testes_qualidade (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    fazenda_id UUID NOT NULL REFERENCES fazendas(id) ON DELETE CASCADE,
    usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    data_teste DATE NOT NULL,
    percentual_gordura DECIMAL(5,2) CHECK (percentual_gordura >= 0 AND percentual_gordura <= 100),
    percentual_proteina DECIMAL(5,2) CHECK (percentual_proteina >= 0 AND percentual_proteina <= 100),
    contagem_celulas_somaticas INTEGER CHECK (contagem_celulas_somaticas >= 0),
    contagem_bacterias_totais INTEGER CHECK (contagem_bacterias_totais >= 0),
    observacoes TEXT,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deletado_em TIMESTAMP WITH TIME ZONE
);

-- Tratamentos Veterinários (Veterinary Treatments)
CREATE TABLE tratamentos_veterinarios (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    fazenda_id UUID NOT NULL REFERENCES fazendas(id) ON DELETE CASCADE,
    animal_id UUID NOT NULL REFERENCES animais(id) ON DELETE CASCADE,
    usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    data_tratamento DATE NOT NULL,
    tipo_tratamento TEXT NOT NULL CHECK (tipo_tratamento IN ('preventivo', 'curativo', 'vacina', 'exame')),
    medicamento TEXT,
    dosagem TEXT,
    veterinario TEXT,
    status_saude TEXT,
    observacoes TEXT,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deletado_em TIMESTAMP WITH TIME ZONE
);

-- =====================================================
-- 3. FINANCIAL TABLES
-- =====================================================

-- Pagamentos (Payments)
CREATE TABLE pagamentos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    fazenda_id UUID NOT NULL REFERENCES fazendas(id) ON DELETE CASCADE,
    data_pagamento DATE NOT NULL,
    volume_litros DECIMAL(10,2) NOT NULL CHECK (volume_litros > 0),
    valor_bruto DECIMAL(10,2) NOT NULL CHECK (valor_bruto >= 0),
    valor_liquido DECIMAL(10,2) NOT NULL CHECK (valor_liquido >= 0),
    status_pagamento TEXT DEFAULT 'pendente' CHECK (status_pagamento IN ('pendente', 'pago', 'atrasado', 'cancelado')),
    metodo_pagamento TEXT CHECK (metodo_pagamento IN ('pix', 'transferencia', 'dinheiro', 'cheque')),
    observacoes TEXT,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deletado_em TIMESTAMP WITH TIME ZONE
);

-- PIX Pagamentos (PIX Payments for subscriptions)
CREATE TABLE pix_pagamentos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    txid TEXT UNIQUE NOT NULL,
    valor DECIMAL(10,2) NOT NULL CHECK (valor > 0),
    status TEXT DEFAULT 'pendente' CHECK (status IN ('pendente', 'confirmado', 'expirado', 'cancelado')),
    chave_pix TEXT NOT NULL,
    tipo_chave_pix TEXT NOT NULL CHECK (tipo_chave_pix IN ('email', 'cpf', 'telefone', 'aleatoria')),
    expira_em TIMESTAMP WITH TIME ZONE NOT NULL,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Assinaturas (Subscriptions)
CREATE TABLE assinaturas (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    pix_pagamento_id UUID REFERENCES pix_pagamentos(id),
    status TEXT DEFAULT 'ativa' CHECK (status IN ('ativa', 'expirada', 'cancelada')),
    tipo_plano TEXT DEFAULT 'mensal' CHECK (tipo_plano IN ('mensal', 'anual')),
    valor DECIMAL(10,2) NOT NULL CHECK (valor > 0),
    inicia_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expira_em TIMESTAMP WITH TIME ZONE NOT NULL,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 4. SYSTEM TABLES
-- =====================================================

-- Configurações de Relatórios (Report Settings)
CREATE TABLE configuracoes_relatorios (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    fazenda_id UUID NOT NULL REFERENCES fazendas(id) ON DELETE CASCADE,
    nome_fazenda_relatorio TEXT,
    logo_fazenda_base64 TEXT,
    texto_rodape TEXT,
    logo_sistema_base64 TEXT,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Logs de Atividades (Activity Logs)
CREATE TABLE logs_atividades (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    fazenda_id UUID NOT NULL REFERENCES fazendas(id) ON DELETE CASCADE,
    usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    acao TEXT NOT NULL,
    tabela_afetada TEXT,
    registro_id UUID,
    dados_anteriores JSONB,
    dados_novos JSONB,
    ip_address INET,
    user_agent TEXT,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 5. INDEXES FOR PERFORMANCE
-- =====================================================

-- Fazendas indexes
CREATE INDEX idx_fazendas_cnpj ON fazendas(cnpj);
CREATE INDEX idx_fazendas_deletado_em ON fazendas(deletado_em);

-- Usuarios indexes
CREATE INDEX idx_usuarios_fazenda_id ON usuarios(fazenda_id);
CREATE INDEX idx_usuarios_email ON usuarios(email);
CREATE INDEX idx_usuarios_cargo ON usuarios(cargo);
CREATE INDEX idx_usuarios_ativo ON usuarios(ativo);
CREATE INDEX idx_usuarios_deletado_em ON usuarios(deletado_em);

-- Animais indexes
CREATE INDEX idx_animais_fazenda_id ON animais(fazenda_id);
CREATE INDEX idx_animais_brinco ON animais(brinco);
CREATE INDEX idx_animais_status ON animais(status);
CREATE INDEX idx_animais_deletado_em ON animais(deletado_em);

-- Produção indexes
CREATE INDEX idx_producao_fazenda_id ON producao_leite(fazenda_id);
CREATE INDEX idx_producao_usuario_id ON producao_leite(usuario_id);
CREATE INDEX idx_producao_data ON producao_leite(data_producao);
CREATE INDEX idx_producao_turno ON producao_leite(turno);
CREATE INDEX idx_producao_deletado_em ON producao_leite(deletado_em);

-- Testes qualidade indexes
CREATE INDEX idx_testes_fazenda_id ON testes_qualidade(fazenda_id);
CREATE INDEX idx_testes_usuario_id ON testes_qualidade(usuario_id);
CREATE INDEX idx_testes_data ON testes_qualidade(data_teste);
CREATE INDEX idx_testes_deletado_em ON testes_qualidade(deletado_em);

-- Tratamentos indexes
CREATE INDEX idx_tratamentos_fazenda_id ON tratamentos_veterinarios(fazenda_id);
CREATE INDEX idx_tratamentos_animal_id ON tratamentos_veterinarios(animal_id);
CREATE INDEX idx_tratamentos_usuario_id ON tratamentos_veterinarios(usuario_id);
CREATE INDEX idx_tratamentos_data ON tratamentos_veterinarios(data_tratamento);
CREATE INDEX idx_tratamentos_tipo ON tratamentos_veterinarios(tipo_tratamento);
CREATE INDEX idx_tratamentos_deletado_em ON tratamentos_veterinarios(deletado_em);

-- Pagamentos indexes
CREATE INDEX idx_pagamentos_fazenda_id ON pagamentos(fazenda_id);
CREATE INDEX idx_pagamentos_data ON pagamentos(data_pagamento);
CREATE INDEX idx_pagamentos_status ON pagamentos(status_pagamento);
CREATE INDEX idx_pagamentos_deletado_em ON pagamentos(deletado_em);

-- PIX pagamentos indexes
CREATE INDEX idx_pix_usuario_id ON pix_pagamentos(usuario_id);
CREATE INDEX idx_pix_txid ON pix_pagamentos(txid);
CREATE INDEX idx_pix_status ON pix_pagamentos(status);
CREATE INDEX idx_pix_expira_em ON pix_pagamentos(expira_em);

-- Assinaturas indexes
CREATE INDEX idx_assinaturas_usuario_id ON assinaturas(usuario_id);
CREATE INDEX idx_assinaturas_status ON assinaturas(status);
CREATE INDEX idx_assinaturas_expira_em ON assinaturas(expira_em);

-- Logs indexes
CREATE INDEX idx_logs_fazenda_id ON logs_atividades(fazenda_id);
CREATE INDEX idx_logs_usuario_id ON logs_atividades(usuario_id);
CREATE INDEX idx_logs_acao ON logs_atividades(acao);
CREATE INDEX idx_logs_criado_em ON logs_atividades(criado_em);

-- =====================================================
-- 6. HELPER FUNCTIONS
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.atualizado_em = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to get current user's farm_id
CREATE OR REPLACE FUNCTION get_current_user_farm_id()
RETURNS UUID AS $$
BEGIN
    RETURN (
        SELECT fazenda_id 
        FROM usuarios 
        WHERE id = auth.uid() 
        AND deletado_em IS NULL
        AND ativo = true
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user has specific role
CREATE OR REPLACE FUNCTION user_has_role(required_role TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(
        SELECT 1 
        FROM usuarios 
        WHERE id = auth.uid() 
        AND cargo = required_role 
        AND ativo = true
        AND deletado_em IS NULL
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user belongs to same farm
CREATE OR REPLACE FUNCTION belongs_to_same_farm(target_farm_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN target_farm_id = get_current_user_farm_id();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 7. TRIGGERS FOR UPDATED_AT
-- =====================================================

CREATE TRIGGER update_fazendas_updated_at 
    BEFORE UPDATE ON fazendas 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_usuarios_updated_at 
    BEFORE UPDATE ON usuarios 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_animais_updated_at 
    BEFORE UPDATE ON animais 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_producao_updated_at 
    BEFORE UPDATE ON producao_leite 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_testes_updated_at 
    BEFORE UPDATE ON testes_qualidade 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tratamentos_updated_at 
    BEFORE UPDATE ON tratamentos_veterinarios 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pagamentos_updated_at 
    BEFORE UPDATE ON pagamentos 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pix_updated_at 
    BEFORE UPDATE ON pix_pagamentos 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_assinaturas_updated_at 
    BEFORE UPDATE ON assinaturas 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_configs_updated_at 
    BEFORE UPDATE ON configuracoes_relatorios 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 8. ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE fazendas ENABLE ROW LEVEL SECURITY;
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE animais ENABLE ROW LEVEL SECURITY;
ALTER TABLE producao_leite ENABLE ROW LEVEL SECURITY;
ALTER TABLE testes_qualidade ENABLE ROW LEVEL SECURITY;
ALTER TABLE tratamentos_veterinarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE pagamentos ENABLE ROW LEVEL SECURITY;
ALTER TABLE pix_pagamentos ENABLE ROW LEVEL SECURITY;
ALTER TABLE assinaturas ENABLE ROW LEVEL SECURITY;
ALTER TABLE configuracoes_relatorios ENABLE ROW LEVEL SECURITY;
ALTER TABLE logs_atividades ENABLE ROW LEVEL SECURITY;

-- Fazendas policies (only current user's farm)
CREATE POLICY "users_own_farm_fazendas" ON fazendas
    FOR ALL USING (id = get_current_user_farm_id());

-- Usuarios policies (same farm isolation)
CREATE POLICY "farm_isolation_usuarios" ON usuarios
    FOR ALL USING (belongs_to_same_farm(fazenda_id));

-- Animais policies (same farm isolation)
CREATE POLICY "farm_isolation_animais" ON animais
    FOR ALL USING (belongs_to_same_farm(fazenda_id));

-- Produção policies (same farm isolation)
CREATE POLICY "farm_isolation_producao" ON producao_leite
    FOR ALL USING (belongs_to_same_farm(fazenda_id));

-- Testes qualidade policies (same farm isolation)
CREATE POLICY "farm_isolation_testes" ON testes_qualidade
    FOR ALL USING (belongs_to_same_farm(fazenda_id));

-- Tratamentos policies (same farm isolation)
CREATE POLICY "farm_isolation_tratamentos" ON tratamentos_veterinarios
    FOR ALL USING (belongs_to_same_farm(fazenda_id));

-- Pagamentos policies (same farm isolation)
CREATE POLICY "farm_isolation_pagamentos" ON pagamentos
    FOR ALL USING (belongs_to_same_farm(fazenda_id));

-- PIX pagamentos policies (user owns their payments)
CREATE POLICY "users_own_pix" ON pix_pagamentos
    FOR ALL USING (auth.uid() = usuario_id);

-- Assinaturas policies (user owns their subscriptions)
CREATE POLICY "users_own_subscriptions" ON assinaturas
    FOR ALL USING (auth.uid() = usuario_id);

-- Configurações policies (same farm isolation)
CREATE POLICY "farm_isolation_configs" ON configuracoes_relatorios
    FOR ALL USING (belongs_to_same_farm(fazenda_id));

-- Logs policies (same farm isolation)
CREATE POLICY "farm_isolation_logs" ON logs_atividades
    FOR ALL USING (belongs_to_same_farm(fazenda_id));

-- =====================================================
-- 9. SETUP FUNCTIONS FOR FIRST ACCESS
-- =====================================================

-- Function to check if farm exists
CREATE OR REPLACE FUNCTION check_farm_exists(p_cnpj TEXT, p_name TEXT)
RETURNS TABLE(exists_cnpj BOOLEAN, exists_name BOOLEAN) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        EXISTS(SELECT 1 FROM fazendas WHERE cnpj = p_cnpj AND deletado_em IS NULL) as exists_cnpj,
        EXISTS(SELECT 1 FROM fazendas WHERE nome_fazenda = p_name AND deletado_em IS NULL) as exists_name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user exists
CREATE OR REPLACE FUNCTION check_user_exists(p_email TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(
        SELECT 1 FROM usuarios 
        WHERE email = p_email 
        AND deletado_em IS NULL
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create initial farm
CREATE OR REPLACE FUNCTION create_initial_farm(
    p_name TEXT,
    p_cnpj TEXT,
    p_phone TEXT DEFAULT NULL,
    p_address TEXT DEFAULT NULL,
    p_city TEXT DEFAULT NULL,
    p_state TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    farm_id UUID;
BEGIN
    INSERT INTO fazendas (nome_fazenda, cnpj, telefone, endereco, cidade, estado)
    VALUES (p_name, p_cnpj, p_phone, p_address, p_city, p_state)
    RETURNING id INTO farm_id;
    
    RETURN farm_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create initial user
CREATE OR REPLACE FUNCTION create_initial_user(
    p_user_id UUID,
    p_farm_id UUID,
    p_name TEXT,
    p_email TEXT,
    p_role TEXT DEFAULT 'proprietario'
)
RETURNS UUID AS $$
BEGIN
    INSERT INTO usuarios (id, fazenda_id, nome, email, cargo)
    VALUES (p_user_id, p_farm_id, p_name, p_email, p_role);
    
    RETURN p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to complete farm setup
CREATE OR REPLACE FUNCTION complete_farm_setup(
    p_farm_id UUID,
    p_user_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
    -- Create initial report configuration
    INSERT INTO configuracoes_relatorios (fazenda_id, nome_fazenda_relatorio)
    SELECT p_farm_id, nome_fazenda 
    FROM fazendas 
    WHERE id = p_farm_id;
    
    -- Log the setup completion
    INSERT INTO logs_atividades (fazenda_id, usuario_id, acao, tabela_afetada)
    VALUES (p_farm_id, p_user_id, 'SETUP_COMPLETO', 'fazendas');
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 10. GRANT PERMISSIONS
-- =====================================================

-- Grant usage on schema
GRANT USAGE ON SCHEMA public TO anon, authenticated;

-- Grant access to tables for authenticated users
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- Grant limited access to anonymous users (for signup/login only)
GRANT SELECT ON fazendas TO anon;
GRANT SELECT ON usuarios TO anon;
GRANT EXECUTE ON FUNCTION check_farm_exists(TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION check_user_exists(TEXT) TO anon;
GRANT EXECUTE ON FUNCTION create_initial_farm(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION create_initial_user(UUID, UUID, TEXT, TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION complete_farm_setup(UUID, UUID) TO anon;

-- =====================================================
-- SCRIPT COMPLETED SUCCESSFULLY
-- =====================================================

-- Final verification
DO $$
BEGIN
    RAISE NOTICE 'LacTech database schema created successfully!';
    RAISE NOTICE 'Tables created: %', (
        SELECT count(*) 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name IN (
            'fazendas', 'usuarios', 'animais', 'producao_leite', 
            'testes_qualidade', 'tratamentos_veterinarios', 'pagamentos', 
            'pix_pagamentos', 'assinaturas', 'configuracoes_relatorios', 'logs_atividades'
        )
    );
    RAISE NOTICE 'Functions created: %', (
        SELECT count(*) 
        FROM information_schema.routines 
        WHERE routine_schema = 'public' 
        AND routine_name IN (
            'update_updated_at_column', 'get_current_user_farm_id', 
            'user_has_role', 'belongs_to_same_farm', 'check_farm_exists',
            'check_user_exists', 'create_initial_farm', 'create_initial_user', 'complete_farm_setup'
        )
    );
END $$;
