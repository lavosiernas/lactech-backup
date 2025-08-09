-- =====================================================
-- CONFIGURAÇÃO COMPLETA DO BANCO DE PAGAMENTOS - LACTECH
-- Execute este SQL no Supabase SQL Editor
-- =====================================================

-- Verificar se as tabelas já existem antes de criar
DO $$
BEGIN
    -- Tabela de pagamentos Pix
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'pix_payments') THEN
        CREATE TABLE pix_payments (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
            txid TEXT UNIQUE NOT NULL,
            amount DECIMAL(10,2) NOT NULL,
            status TEXT CHECK (status IN ('pending', 'confirmed', 'expired', 'cancelled')) DEFAULT 'pending',
            pix_key TEXT NOT NULL,
            pix_key_type TEXT CHECK (pix_key_type IN ('email', 'cpf', 'telefone', 'aleatoria')) NOT NULL,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            expires_at TIMESTAMP WITH TIME ZONE NOT NULL
        );
        RAISE NOTICE 'Tabela pix_payments criada com sucesso!';
    ELSE
        RAISE NOTICE 'Tabela pix_payments já existe.';
    END IF;

    -- Tabela de pagamentos com cartão
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'card_payments') THEN
        CREATE TABLE card_payments (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
            payment_intent_id TEXT UNIQUE,
            amount DECIMAL(10,2) NOT NULL,
            status TEXT CHECK (status IN ('pending', 'confirmed', 'failed', 'cancelled')) DEFAULT 'pending',
            payment_method TEXT CHECK (payment_method IN ('card', 'pix')) NOT NULL,
            card_last4 TEXT,
            card_brand TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        RAISE NOTICE 'Tabela card_payments criada com sucesso!';
    ELSE
        RAISE NOTICE 'Tabela card_payments já existe.';
    END IF;

    -- Tabela de assinaturas
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'subscriptions') THEN
        CREATE TABLE subscriptions (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
            payment_id UUID,
            payment_type TEXT CHECK (payment_type IN ('pix', 'card')) NOT NULL,
            status TEXT CHECK (status IN ('active', 'expired', 'cancelled')) DEFAULT 'active',
            plan_type TEXT CHECK (plan_type IN ('monthly', 'yearly')) DEFAULT 'monthly',
            amount DECIMAL(10,2) NOT NULL,
            starts_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        RAISE NOTICE 'Tabela subscriptions criada com sucesso!';
    ELSE
        RAISE NOTICE 'Tabela subscriptions já existe.';
    END IF;
END $$;

-- =====================================================
-- ÍNDICES PARA PERFORMANCE
-- =====================================================

-- Índices para pix_payments
CREATE INDEX IF NOT EXISTS idx_pix_payments_user_id ON pix_payments(user_id);
CREATE INDEX IF NOT EXISTS idx_pix_payments_txid ON pix_payments(txid);
CREATE INDEX IF NOT EXISTS idx_pix_payments_status ON pix_payments(status);
CREATE INDEX IF NOT EXISTS idx_pix_payments_created_at ON pix_payments(created_at);
CREATE INDEX IF NOT EXISTS idx_pix_payments_expires_at ON pix_payments(expires_at);

-- Índices para card_payments
CREATE INDEX IF NOT EXISTS idx_card_payments_user_id ON card_payments(user_id);
CREATE INDEX IF NOT EXISTS idx_card_payments_payment_intent_id ON card_payments(payment_intent_id);
CREATE INDEX IF NOT EXISTS idx_card_payments_status ON card_payments(status);
CREATE INDEX IF NOT EXISTS idx_card_payments_created_at ON card_payments(created_at);

-- Índices para subscriptions
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_expires_at ON subscriptions(expires_at);
CREATE INDEX IF NOT EXISTS idx_subscriptions_payment_id ON subscriptions(payment_id);

-- =====================================================
-- RLS (ROW LEVEL SECURITY)
-- =====================================================

-- Habilitar RLS nas tabelas
ALTER TABLE pix_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE card_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- POLÍTICAS DE SEGURANÇA
-- =====================================================

-- Políticas para pix_payments
DROP POLICY IF EXISTS "Users can view their own pix payments" ON pix_payments;
CREATE POLICY "Users can view their own pix payments" ON pix_payments
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own pix payments" ON pix_payments;
CREATE POLICY "Users can insert their own pix payments" ON pix_payments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own pix payments" ON pix_payments;
CREATE POLICY "Users can update their own pix payments" ON pix_payments
    FOR UPDATE USING (auth.uid() = user_id);

-- Políticas para card_payments
DROP POLICY IF EXISTS "Users can view their own card payments" ON card_payments;
CREATE POLICY "Users can view their own card payments" ON card_payments
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own card payments" ON card_payments;
CREATE POLICY "Users can insert their own card payments" ON card_payments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own card payments" ON card_payments;
CREATE POLICY "Users can update their own card payments" ON card_payments
    FOR UPDATE USING (auth.uid() = user_id);

-- Políticas para subscriptions
DROP POLICY IF EXISTS "Users can view their own subscriptions" ON subscriptions;
CREATE POLICY "Users can view their own subscriptions" ON subscriptions
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own subscriptions" ON subscriptions;
CREATE POLICY "Users can insert their own subscriptions" ON subscriptions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own subscriptions" ON subscriptions;
CREATE POLICY "Users can update their own subscriptions" ON subscriptions
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
DROP TRIGGER IF EXISTS update_pix_payments_updated_at ON pix_payments;
CREATE TRIGGER update_pix_payments_updated_at BEFORE UPDATE ON pix_payments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_card_payments_updated_at ON card_payments;
CREATE TRIGGER update_card_payments_updated_at BEFORE UPDATE ON card_payments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_subscriptions_updated_at ON subscriptions;
CREATE TRIGGER update_subscriptions_updated_at BEFORE UPDATE ON subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- FUNÇÃO PARA EXPIRAR PAGAMENTOS
-- =====================================================

CREATE OR REPLACE FUNCTION expire_old_payments()
RETURNS void AS $$
BEGIN
    -- Marcar pagamentos Pix expirados
    UPDATE pix_payments 
    SET status = 'expired', updated_at = NOW()
    WHERE status = 'pending' 
    AND expires_at < NOW();
    
    -- Log da quantidade atualizada
    RAISE NOTICE 'Pagamentos Pix expirados atualizados: %', ROW_COUNT;
    
    -- Marcar assinaturas expiradas
    UPDATE subscriptions 
    SET status = 'expired', updated_at = NOW()
    WHERE status = 'active' 
    AND expires_at < NOW();
    
    -- Log da quantidade atualizada
    RAISE NOTICE 'Assinaturas expiradas atualizadas: %', ROW_COUNT;
END;
$$ language 'plpgsql';

-- =====================================================
-- DADOS INICIAIS (OPCIONAL)
-- =====================================================

-- Criar tabela de configurações se não existir
CREATE TABLE IF NOT EXISTS payment_settings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    key TEXT UNIQUE NOT NULL,
    value TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Inserir configurações padrão
INSERT INTO payment_settings (key, value, description) 
VALUES 
    ('pix_key', 'slavosier298@gmail.com', 'Chave PIX para recebimento de pagamentos'),
    ('pix_key_type', 'email', 'Tipo da chave PIX (email, cpf, telefone, aleatoria)'),
    ('monthly_price', '1.00', 'Preço da assinatura mensal em reais'),
    ('yearly_price', '2.00', 'Preço da assinatura anual em reais'),
    ('payment_timeout_minutes', '30', 'Tempo limite para pagamento em minutos')
ON CONFLICT (key) DO NOTHING;

-- =====================================================
-- VERIFICAÇÃO FINAL
-- =====================================================

-- Listar todas as tabelas criadas
DO $$
DECLARE
    table_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO table_count
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name IN ('pix_payments', 'card_payments', 'subscriptions', 'payment_settings');
    
    RAISE NOTICE '======================================';
    RAISE NOTICE 'CONFIGURAÇÃO CONCLUÍDA!';
    RAISE NOTICE 'Tabelas de pagamento criadas: %', table_count;
    RAISE NOTICE '======================================';
    
    -- Mostrar detalhes das tabelas
    RAISE NOTICE 'Tabelas disponíveis:';
    RAISE NOTICE '- pix_payments (pagamentos PIX)';
    RAISE NOTICE '- card_payments (pagamentos cartão)';
    RAISE NOTICE '- subscriptions (assinaturas)';
    RAISE NOTICE '- payment_settings (configurações)';
    RAISE NOTICE '======================================';
END $$;