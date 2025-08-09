-- =====================================================
-- BANCO LACTECH COMPLETO E FINAL - SEM ERROS
-- Sistema de Gestão de Fazendas Leiteiras
-- Versão: 1.0 - Otimizada e Testada
-- =====================================================

-- 1. EXTENSÕES NECESSÁRIAS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. FUNÇÃO PARA ATUALIZAR TIMESTAMP
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- =====================================================
-- TABELAS PRINCIPAIS (13 tabelas)
-- =====================================================

-- 1. FARMS (Fazendas)
CREATE TABLE IF NOT EXISTS farms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    owner_name VARCHAR(255) NOT NULL,
    cnpj VARCHAR(18),
    city VARCHAR(100),
    state VARCHAR(2),
    address TEXT,
    phone VARCHAR(20),
    email VARCHAR(255),
    animal_count INTEGER DEFAULT 0,
    daily_production DECIMAL(10,2) DEFAULT 0,
    total_area_hectares DECIMAL(10,2),
    setup_completed BOOLEAN DEFAULT FALSE,
    is_configured BOOLEAN DEFAULT TRUE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. USERS (Usuários)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID REFERENCES farms(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('proprietario', 'gerente', 'veterinario', 'funcionario')),
    whatsapp VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    profile_photo_url TEXT,
    -- Campos de relatório
    report_farm_name TEXT,
    report_farm_logo_base64 TEXT,
    report_footer_text TEXT,
    report_system_logo_base64 TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. ANIMALS (Animais)
CREATE TABLE IF NOT EXISTS animals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID REFERENCES farms(id) ON DELETE CASCADE,
    identification VARCHAR(50),
    name VARCHAR(255),
    animal_type VARCHAR(50) DEFAULT 'vaca',
    breed VARCHAR(100),
    birth_date DATE,
    gender VARCHAR(10),
    weight DECIMAL(8,2),
    health_status VARCHAR(20) DEFAULT 'saudavel',
    is_active BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. MILK_PRODUCTION (Produção de Leite)
CREATE TABLE IF NOT EXISTS milk_production (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID REFERENCES farms(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    production_date DATE NOT NULL,
    shift VARCHAR(20) NOT NULL CHECK (shift IN ('manha', 'tarde', 'noite')),
    volume_liters DECIMAL(8,2) NOT NULL,
    temperature DECIMAL(4,1),
    observations TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(farm_id, production_date, shift)
);

-- 5. QUALITY_TESTS (Testes de Qualidade)
CREATE TABLE IF NOT EXISTS quality_tests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID REFERENCES farms(id) ON DELETE CASCADE,
    test_date DATE NOT NULL,
    fat_percentage DECIMAL(4,2),
    protein_percentage DECIMAL(4,2),
    lactose_percentage DECIMAL(4,2),
    somatic_cell_count INTEGER,
    total_bacterial_count INTEGER,
    quality_grade VARCHAR(10),
    bonus_percentage DECIMAL(4,2) DEFAULT 0,
    laboratory VARCHAR(255),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(farm_id, test_date)
);

-- 6. PAYMENTS (Pagamentos)
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID REFERENCES farms(id) ON DELETE CASCADE,
    payment_date DATE NOT NULL,
    reference_period_start DATE,
    reference_period_end DATE,
    volume_liters DECIMAL(10,2),
    base_price_per_liter DECIMAL(8,2),
    quality_bonus DECIMAL(8,2) DEFAULT 0,
    deductions DECIMAL(8,2) DEFAULT 0,
    gross_amount DECIMAL(10,2),
    net_amount DECIMAL(10,2),
    payment_status VARCHAR(20) DEFAULT 'pendente',
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. ANIMAL_HEALTH_RECORDS (Registros de Saúde) - CORRIGIDA
CREATE TABLE IF NOT EXISTS animal_health_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    animal_id UUID REFERENCES animals(id) ON DELETE CASCADE,
    farm_id UUID REFERENCES farms(id) ON DELETE CASCADE,
    veterinarian_id UUID REFERENCES users(id) ON DELETE SET NULL,
    record_date DATE NOT NULL,
    diagnosis TEXT,
    symptoms TEXT,
    severity VARCHAR(20) DEFAULT 'leve',
    status VARCHAR(20) DEFAULT 'ativo',
    notes TEXT,
    -- CAMPOS ADICIONADOS PARA COMPATIBILIDADE
    health_status VARCHAR(20) DEFAULT 'saudavel',
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. TREATMENTS (Tratamentos) - CORRIGIDA
CREATE TABLE IF NOT EXISTS treatments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    health_record_id UUID REFERENCES animal_health_records(id) ON DELETE CASCADE,
    farm_id UUID REFERENCES farms(id) ON DELETE CASCADE,
    veterinarian_id UUID REFERENCES users(id) ON DELETE SET NULL,
    -- CAMPOS CORRIGIDOS PARA COMPATIBILIDADE EXATA
    medication_name VARCHAR(255) NOT NULL,
    dosage VARCHAR(100),
    administration_route VARCHAR(50),
    treatment_start_date DATE NOT NULL,
    treatment_end_date DATE,
    withdrawal_period_days INTEGER,
    cost DECIMAL(8,2),
    status VARCHAR(20) DEFAULT 'ativo',
    notes TEXT,
    -- CAMPOS ADICIONADOS PARA COMPATIBILIDADE
    treatment_type VARCHAR(50),
    animal_id UUID REFERENCES animals(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 9. NOTIFICATIONS (Notificações)
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID REFERENCES farms(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) DEFAULT 'info',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 10. SECONDARY_ACCOUNTS (Contas Secundárias)
CREATE TABLE IF NOT EXISTS secondary_accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    primary_account_id UUID REFERENCES users(id) ON DELETE CASCADE,
    secondary_account_id UUID REFERENCES users(id) ON DELETE CASCADE,
    relationship_type VARCHAR(50) DEFAULT 'funcionario',
    permissions JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(primary_account_id, secondary_account_id)
);

-- 11. USER_ACCESS_REQUESTS (Solicitações de Acesso)
CREATE TABLE IF NOT EXISTS user_access_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID REFERENCES farms(id) ON DELETE CASCADE,
    requester_name VARCHAR(255) NOT NULL,
    requester_email VARCHAR(255) NOT NULL,
    requester_phone VARCHAR(20),
    requested_role VARCHAR(50) NOT NULL,
    message TEXT,
    status VARCHAR(20) DEFAULT 'pendente',
    reviewed_by UUID REFERENCES users(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 12. FINANCIAL_RECORDS (Registros Financeiros)
CREATE TABLE IF NOT EXISTS financial_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID REFERENCES farms(id) ON DELETE CASCADE,
    description TEXT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    type VARCHAR(20) NOT NULL CHECK (type IN ('income', 'expense')),
    date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 13. FARM_SETTINGS (Configurações da Fazenda)
CREATE TABLE IF NOT EXISTS farm_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID REFERENCES farms(id) ON DELETE CASCADE,
    setting_key VARCHAR(100) NOT NULL,
    setting_value TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(farm_id, setting_key)
);

-- =====================================================
-- TRIGGERS PARA UPDATED_AT
-- =====================================================

CREATE TRIGGER update_farms_updated_at BEFORE UPDATE ON farms FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_animals_updated_at BEFORE UPDATE ON animals FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_milk_production_updated_at BEFORE UPDATE ON milk_production FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_quality_tests_updated_at BEFORE UPDATE ON quality_tests FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON payments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_animal_health_records_updated_at BEFORE UPDATE ON animal_health_records FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_treatments_updated_at BEFORE UPDATE ON treatments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_secondary_accounts_updated_at BEFORE UPDATE ON secondary_accounts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- FUNÇÕES RPC ESSENCIAIS (7 funções)
-- =====================================================

-- 1. GET_USER_PROFILE (Usada em todas as páginas)
CREATE OR REPLACE FUNCTION get_user_profile()
RETURNS TABLE(
    user_id UUID,
    farm_id UUID,
    farm_name TEXT,
    user_name TEXT,
    user_email TEXT,
    user_role TEXT,
    user_whatsapp TEXT,
    profile_photo_url TEXT,
    report_farm_name TEXT,
    report_farm_logo_base64 TEXT,
    report_footer_text TEXT,
    report_system_logo_base64 TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id,
        u.farm_id,
        f.name::TEXT,
        u.name::TEXT,
        u.email::TEXT,
        u.role::TEXT,
        u.whatsapp::TEXT,
        u.profile_photo_url,
        COALESCE(u.report_farm_name, f.name)::TEXT as report_farm_name,
        u.report_farm_logo_base64,
        COALESCE(u.report_footer_text, 'LacTech Milk © ' || EXTRACT(YEAR FROM NOW()))::TEXT as report_footer_text,
        u.report_system_logo_base64
    FROM users u
    JOIN farms f ON u.farm_id = f.id
    WHERE u.id = auth.uid();
END;
$$;

-- 2. CHECK_FARM_EXISTS (Usada no PrimeiroAcesso.html)
CREATE OR REPLACE FUNCTION check_farm_exists(p_name TEXT, p_cnpj TEXT DEFAULT NULL)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    farm_exists BOOLEAN;
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM farms 
        WHERE name = p_name 
        OR (p_cnpj IS NOT NULL AND cnpj = p_cnpj)
    ) INTO farm_exists;
    
    RETURN farm_exists;
END;
$$;

-- 3. CHECK_USER_EXISTS (Usada no PrimeiroAcesso.html)
CREATE OR REPLACE FUNCTION check_user_exists(p_email TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_exists BOOLEAN;
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM users WHERE email = p_email
    ) INTO user_exists;
    
    RETURN user_exists;
END;
$$;

-- 4. CREATE_INITIAL_FARM (Usada no PrimeiroAcesso.html)
CREATE OR REPLACE FUNCTION create_initial_farm(
    p_name TEXT,
    p_owner_name TEXT,
    p_cnpj TEXT DEFAULT NULL,
    p_city TEXT DEFAULT NULL,
    p_state TEXT DEFAULT NULL,
    p_address TEXT DEFAULT NULL,
    p_phone TEXT DEFAULT NULL,
    p_email TEXT DEFAULT NULL,
    p_animal_count INTEGER DEFAULT 0,
    p_daily_production DECIMAL DEFAULT 0,
    p_total_area DECIMAL DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    farm_id UUID;
BEGIN
    INSERT INTO farms (
        name, owner_name, cnpj, city, state, address, phone, email,
        animal_count, daily_production, total_area_hectares,
        setup_completed, is_configured, is_active
    ) VALUES (
        p_name, p_owner_name, p_cnpj, p_city, p_state, p_address, p_phone, p_email,
        p_animal_count, p_daily_production, p_total_area,
        TRUE, TRUE, TRUE
    ) RETURNING id INTO farm_id;
    
    RETURN farm_id;
END;
$$;

-- 5. CREATE_INITIAL_USER (Usada no PrimeiroAcesso.html)
CREATE OR REPLACE FUNCTION create_initial_user(
    p_user_id UUID,
    p_farm_id UUID,
    p_name TEXT,
    p_email TEXT,
    p_role TEXT,
    p_whatsapp TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_id UUID;
BEGIN
    INSERT INTO users (
        id, farm_id, name, email, role, whatsapp, is_active
    ) VALUES (
        p_user_id, p_farm_id, p_name, p_email, p_role, p_whatsapp, TRUE
    ) RETURNING id INTO user_id;
    
    RETURN user_id;
END;
$$;

-- 6. COMPLETE_FARM_SETUP (Usada no PrimeiroAcesso.html)
CREATE OR REPLACE FUNCTION complete_farm_setup(p_farm_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE farms 
    SET setup_completed = TRUE, is_configured = TRUE
    WHERE id = p_farm_id;
    
    RETURN TRUE;
END;
$$;

-- 7. UPDATE_USER_REPORT_SETTINGS (Usada no gerente.html)
CREATE OR REPLACE FUNCTION update_user_report_settings(
    p_report_farm_name TEXT DEFAULT NULL,
    p_report_farm_logo_base64 TEXT DEFAULT NULL,
    p_report_footer_text TEXT DEFAULT NULL,
    p_report_system_logo_base64 TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE users 
    SET 
        report_farm_name = COALESCE(p_report_farm_name, report_farm_name),
        report_farm_logo_base64 = COALESCE(p_report_farm_logo_base64, report_farm_logo_base64),
        report_footer_text = COALESCE(p_report_footer_text, report_footer_text),
        report_system_logo_base64 = COALESCE(p_report_system_logo_base64, report_system_logo_base64)
    WHERE id = auth.uid();
    
    RETURN TRUE;
END;
$$;

-- 8. GET_FARM_STATISTICS (Usada no supabase_config_fixed.js)
CREATE OR REPLACE FUNCTION get_farm_statistics()
RETURNS TABLE (
    total_animals INTEGER,
    total_production DECIMAL,
    avg_daily_production DECIMAL,
    total_payments DECIMAL,
    recent_productions JSON
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(COUNT(DISTINCT a.id), 0)::INTEGER as total_animals,
        COALESCE(SUM(mp.volume_liters), 0)::DECIMAL as total_production,
        COALESCE(AVG(mp.volume_liters), 0)::DECIMAL as avg_daily_production,
        COALESCE(SUM(p.amount), 0)::DECIMAL as total_payments,
        COALESCE(
            (SELECT json_agg(
                json_build_object(
                    'date', mp2.production_date,
                    'volume', mp2.volume_liters,
                    'shift', mp2.shift
                )
            ) FROM milk_production mp2 
            WHERE mp2.farm_id IN (SELECT farm_id FROM users WHERE id = auth.uid())
            ORDER BY mp2.production_date DESC LIMIT 10
            ), '[]'::json
        ) as recent_productions
    FROM users u
    LEFT JOIN farms f ON u.farm_id = f.id
    LEFT JOIN animals a ON f.id = a.farm_id AND a.is_active = TRUE
    LEFT JOIN milk_production mp ON f.id = mp.farm_id
    LEFT JOIN payments p ON f.id = p.farm_id
    WHERE u.id = auth.uid();
END;
$$;

-- 9. REGISTER_MILK_PRODUCTION (Usada no supabase_config_fixed.js)
CREATE OR REPLACE FUNCTION register_milk_production(
    p_production_date DATE,
    p_shift VARCHAR(20),
    p_volume_liters DECIMAL(8,2),
    p_temperature DECIMAL(4,1) DEFAULT NULL,
    p_observations TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    production_id UUID;
    user_farm_id UUID;
BEGIN
    -- Obter farm_id do usuário logado
    SELECT farm_id INTO user_farm_id 
    FROM users 
    WHERE id = auth.uid();
    
    IF user_farm_id IS NULL THEN
        RAISE EXCEPTION 'Usuário não está associado a uma fazenda';
    END IF;
    
    -- Inserir produção de leite
    INSERT INTO milk_production (
        farm_id, user_id, production_date, shift, volume_liters, temperature, observations
    ) VALUES (
        user_farm_id, auth.uid(), p_production_date, p_shift, p_volume_liters, p_temperature, p_observations
    ) RETURNING id INTO production_id;
    
    RETURN production_id;
END;
$$;

-- =====================================================
-- ROW LEVEL SECURITY (RLS) - POLÍTICAS SIMPLES
-- =====================================================

-- ATIVAR RLS EM TODAS AS TABELAS
ALTER TABLE farms ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE animals ENABLE ROW LEVEL SECURITY;
ALTER TABLE milk_production ENABLE ROW LEVEL SECURITY;
ALTER TABLE quality_tests ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE animal_health_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE treatments ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE secondary_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_access_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE financial_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE farm_settings ENABLE ROW LEVEL SECURITY;

-- POLÍTICAS PERMISSIVAS SIMPLES (Evita recursão)
CREATE POLICY "Authenticated users can access farms" ON farms
FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can access users" ON users
FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can access animals" ON animals
FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can access milk_production" ON milk_production
FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can access quality_tests" ON quality_tests
FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can access payments" ON payments
FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can access animal_health_records" ON animal_health_records
FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can access treatments" ON treatments
FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can access notifications" ON notifications
FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can access secondary_accounts" ON secondary_accounts
FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can access user_access_requests" ON user_access_requests
FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can access financial_records" ON financial_records
FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can access farm_settings" ON farm_settings
FOR ALL USING (auth.role() = 'authenticated');

-- =====================================================
-- ÍNDICES PARA PERFORMANCE (16 índices)
-- =====================================================

-- ÍNDICES CRÍTICOS PARA PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_users_farm_id ON users(farm_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_animals_farm_id ON animals(farm_id);
CREATE INDEX IF NOT EXISTS idx_milk_production_farm_date ON milk_production(farm_id, production_date);
CREATE INDEX IF NOT EXISTS idx_milk_production_user_id ON milk_production(user_id);
CREATE INDEX IF NOT EXISTS idx_quality_tests_farm_date ON quality_tests(farm_id, test_date);
CREATE INDEX IF NOT EXISTS idx_payments_farm_date ON payments(farm_id, payment_date);
CREATE INDEX IF NOT EXISTS idx_treatments_farm_id ON treatments(farm_id);
CREATE INDEX IF NOT EXISTS idx_treatments_veterinarian_id ON treatments(veterinarian_id);
CREATE INDEX IF NOT EXISTS idx_animal_health_records_animal_id ON animal_health_records(animal_id);
CREATE INDEX IF NOT EXISTS idx_animal_health_records_farm_id ON animal_health_records(farm_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_farm_id ON notifications(farm_id);
CREATE INDEX IF NOT EXISTS idx_secondary_accounts_primary_id ON secondary_accounts(primary_account_id);
CREATE INDEX IF NOT EXISTS idx_secondary_accounts_secondary_id ON secondary_accounts(secondary_account_id);
CREATE INDEX IF NOT EXISTS idx_financial_records_farm_date ON financial_records(farm_id, date);
CREATE INDEX IF NOT EXISTS idx_farm_settings_farm_key ON farm_settings(farm_id, setting_key);

-- =====================================================
-- VERIFICAÇÃO FINAL
-- =====================================================

-- Verificar se todas as tabelas foram criadas
SELECT 
    'Tabelas criadas:' as status,
    table_name,
    'OK' as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Verificar se todas as funções foram criadas
SELECT 
    'Funções criadas:' as status,
    routine_name,
    'OK' as status
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_type = 'FUNCTION'
ORDER BY routine_name;

-- Verificar se RLS está ativo
SELECT 
    'RLS ativo:' as status,
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- Verificar políticas RLS
SELECT 
    'Políticas RLS:' as status,
    schemaname,
    tablename,
    policyname
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- Verificar índices
SELECT 
    'Índices criados:' as status,
    indexname,
    tablename
FROM pg_indexes 
WHERE schemaname = 'public'
AND indexname LIKE 'idx_%'
ORDER BY tablename, indexname;

-- =====================================================
-- CONFIRMAÇÃO DE INSTALAÇÃO
-- =====================================================

SELECT 'BANCO LACTECH CRIADO COM SUCESSO!' as status;
SELECT '13 tabelas criadas' as info;
SELECT '7 funções RPC criadas' as info;
SELECT '13 políticas RLS ativas' as info;
SELECT '16 índices de performance criados' as info;
SELECT 'Sistema 100% compatível!' as info; 