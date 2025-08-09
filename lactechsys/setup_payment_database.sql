-- =====================================================
-- CONFIGURAÇÃO COMPLETA DO BANCO DE PAGAMENTOS
-- =====================================================

-- =====================================================
-- TABELAS PRINCIPAIS
-- =====================================================

-- Tabela de pagamentos Pix
CREATE TABLE IF NOT EXISTS pix_payments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    txid TEXT UNIQUE NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    status TEXT CHECK (status IN ('pending', 'confirmed', 'expired', 'cancelled')) DEFAULT 'pending',
    pix_key TEXT NOT NULL,
    pix_key_type TEXT CHECK (pix_key_type IN ('email', 'cpf', 'telefone', 'aleatoria')) NOT NULL,
    description TEXT,
    emv_qr_code TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL
);

-- Tabela de assinaturas
CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    payment_id UUID REFERENCES pix_payments(id),
    status TEXT CHECK (status IN ('active', 'expired', 'cancelled')) DEFAULT 'active',
    plan_type TEXT CHECK (plan_type IN ('monthly', 'yearly')) DEFAULT 'monthly',
    amount DECIMAL(10,2) NOT NULL,
    starts_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
// ÍNDICES PARA PERFORMANCE
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_pix_payments_user_id ON pix_payments(user_id);
CREATE INDEX IF NOT EXISTS idx_pix_payments_txid ON pix_payments(txid);
CREATE INDEX IF NOT EXISTS idx_pix_payments_status ON pix_payments(status);
CREATE INDEX IF NOT EXISTS idx_pix_payments_expires_at ON pix_payments(expires_at);
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_expires_at ON subscriptions(expires_at);

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================

ALTER TABLE pix_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- Políticas para pix_payments
CREATE POLICY IF NOT EXISTS "Users can view their own payments" ON pix_payments
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY IF NOT EXISTS "Users can insert their own payments" ON pix_payments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY IF NOT EXISTS "Users can update their own payments" ON pix_payments
    FOR UPDATE USING (auth.uid() = user_id);

-- Políticas para subscriptions
CREATE POLICY IF NOT EXISTS "Users can view their own subscriptions" ON subscriptions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY IF NOT EXISTS "Users can insert their own subscriptions" ON subscriptions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY IF NOT EXISTS "Users can update their own subscriptions" ON subscriptions
    FOR UPDATE USING (auth.uid() = user_id);

-- =====================================================
-- FUNÇÕES E TRIGGERS
-- =====================================================

-- Função para atualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers para atualizar updated_at
CREATE TRIGGER IF NOT EXISTS update_pix_payments_updated_at BEFORE UPDATE ON pix_payments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER IF NOT EXISTS update_subscriptions_updated_at BEFORE UPDATE ON subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- FUNÇÕES ÚTEIS PARA O SISTEMA
-- =====================================================

-- Função para criar um novo pagamento PIX
CREATE OR REPLACE FUNCTION create_pix_payment(
    p_user_id UUID,
    p_amount DECIMAL(10,2),
    p_pix_key TEXT,
    p_pix_key_type TEXT DEFAULT 'email',
    p_description TEXT DEFAULT NULL
)
RETURNS pix_payments AS $$
DECLARE
    new_payment pix_payments;
    txid_text TEXT;
BEGIN
    -- Gerar TXID único
    txid_text := 'TX' || extract(epoch from now())::text || floor(random() * 1000)::text;
    
    -- Inserir pagamento
    INSERT INTO pix_payments (
        user_id, txid, amount, pix_key, pix_key_type, 
        description, expires_at
    ) VALUES (
        p_user_id, txid_text, p_amount, p_pix_key, p_pix_key_type,
        p_description, NOW() + INTERVAL '30 minutes'
    ) RETURNING * INTO new_payment;
    
    RETURN new_payment;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para confirmar pagamento
CREATE OR REPLACE FUNCTION confirm_pix_payment(p_txid TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    payment_record pix_payments;
BEGIN
    -- Buscar pagamento
    SELECT * INTO payment_record 
    FROM pix_payments 
    WHERE txid = p_txid AND status = 'pending';
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Verificar se não expirou
    IF payment_record.expires_at < NOW() THEN
        UPDATE pix_payments SET status = 'expired' WHERE txid = p_txid;
        RETURN FALSE;
    END IF;
    
    -- Confirmar pagamento
    UPDATE pix_payments 
    SET status = 'confirmed' 
    WHERE txid = p_txid;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para buscar pagamentos do usuário atual (segura)
CREATE OR REPLACE FUNCTION get_user_payments()
RETURNS TABLE (
    id UUID,
    txid TEXT,
    amount DECIMAL(10,2),
    status TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    pix_key TEXT,
    pix_key_type TEXT,
    description TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.txid,
        p.amount,
        p.status,
        p.created_at,
        p.expires_at,
        p.pix_key,
        p.pix_key_type,
        p.description
    FROM pix_payments p
    WHERE p.user_id = auth.uid()
    ORDER BY p.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para buscar assinaturas do usuário atual (segura)
CREATE OR REPLACE FUNCTION get_user_subscriptions()
RETURNS TABLE (
    id UUID,
    plan_type TEXT,
    amount DECIMAL(10,2),
    status TEXT,
    starts_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    payment_txid TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id,
        s.plan_type,
        s.amount,
        s.status,
        s.starts_at,
        s.expires_at,
        p.txid as payment_txid
    FROM subscriptions s
    LEFT JOIN pix_payments p ON s.payment_id = p.id
    WHERE s.user_id = auth.uid()
    ORDER BY s.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para buscar pagamentos pendentes (segura)
CREATE OR REPLACE FUNCTION get_pending_payments()
RETURNS TABLE (
    id UUID,
    txid TEXT,
    amount DECIMAL(10,2),
    status TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    pix_key TEXT,
    pix_key_type TEXT,
    description TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.txid,
        p.amount,
        p.status,
        p.created_at,
        p.expires_at,
        p.pix_key,
        p.pix_key_type,
        p.description
    FROM pix_payments p
    WHERE p.status = 'pending'
    ORDER BY p.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para buscar assinaturas ativas (segura)
CREATE OR REPLACE FUNCTION get_active_subscriptions()
RETURNS TABLE (
    id UUID,
    plan_type TEXT,
    amount DECIMAL(10,2),
    status TEXT,
    starts_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    payment_txid TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id,
        s.plan_type,
        s.amount,
        s.status,
        s.starts_at,
        s.expires_at,
        p.txid as payment_txid
    FROM subscriptions s
    LEFT JOIN pix_payments p ON s.payment_id = p.id
    WHERE s.status = 'active' AND s.expires_at > NOW()
    ORDER BY s.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- DADOS DE EXEMPLO (OPCIONAL)
-- =====================================================

-- Inserir dados de exemplo para teste (remover em produção)
-- INSERT INTO pix_payments (user_id, txid, amount, pix_key, pix_key_type, description, expires_at)
-- VALUES (
--     '00000000-0000-0000-0000-000000000000', -- Substituir por user_id real
--     'TX1234567890',
--     1.00,
--     'slavosier298@gmail.com',
--     'email',
--     'Plano mensal - teste',
--     NOW() + INTERVAL '30 minutes'
-- );

-- =====================================================
-- VERIFICAÇÃO FINAL
-- =====================================================

-- Verificar se as tabelas foram criadas
SELECT 
    schemaname,
    tablename,
    tabletype
FROM pg_tables 
WHERE tablename IN ('pix_payments', 'subscriptions');

-- Verificar se as funções foram criadas
SELECT 
    proname,
    prosrc
FROM pg_proc 
WHERE proname IN ('get_user_payments', 'get_user_subscriptions', 'get_pending_payments', 'get_active_subscriptions');

-- Verificar se os índices foram criados
SELECT 
    indexname,
    tablename
FROM pg_indexes 
WHERE tablename IN ('pix_payments', 'subscriptions');

-- Verificar se as políticas RLS foram criadas
SELECT 
    schemaname,
    tablename,
    policyname
FROM pg_policies 
WHERE tablename IN ('pix_payments', 'subscriptions');
