-- =====================================================
-- TABELAS DO SISTEMA DE PAGAMENTO - LACTECH
-- =====================================================

-- Tabela de pagamentos Pix
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

-- Tabela de pagamentos com cartão
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

-- Tabela de assinaturas
CREATE TABLE subscriptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    payment_id UUID, -- Pode ser de pix_payments ou card_payments
    payment_type TEXT CHECK (payment_type IN ('pix', 'card')) NOT NULL,
    status TEXT CHECK (status IN ('active', 'expired', 'cancelled')) DEFAULT 'active',
    plan_type TEXT CHECK (plan_type IN ('monthly', 'yearly')) DEFAULT 'monthly',
    amount DECIMAL(10,2) NOT NULL,
    starts_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_pix_payments_user_id ON pix_payments(user_id);
CREATE INDEX idx_pix_payments_txid ON pix_payments(txid);
CREATE INDEX idx_pix_payments_status ON pix_payments(status);
CREATE INDEX idx_card_payments_user_id ON card_payments(user_id);
CREATE INDEX idx_card_payments_payment_intent_id ON card_payments(payment_intent_id);
CREATE INDEX idx_card_payments_status ON card_payments(status);
CREATE INDEX idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);
CREATE INDEX idx_subscriptions_expires_at ON subscriptions(expires_at);

-- RLS (Row Level Security)
ALTER TABLE pix_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE card_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- Políticas para pix_payments
CREATE POLICY "Users can view their own pix payments" ON pix_payments
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own pix payments" ON pix_payments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own pix payments" ON pix_payments
    FOR UPDATE USING (auth.uid() = user_id);

-- Políticas para card_payments
CREATE POLICY "Users can view their own card payments" ON card_payments
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own card payments" ON card_payments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own card payments" ON card_payments
    FOR UPDATE USING (auth.uid() = user_id);

-- Políticas para subscriptions
CREATE POLICY "Users can view their own subscriptions" ON subscriptions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own subscriptions" ON subscriptions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own subscriptions" ON subscriptions
    FOR UPDATE USING (auth.uid() = user_id);

-- Função para atualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers para atualizar updated_at
CREATE TRIGGER update_pix_payments_updated_at BEFORE UPDATE ON pix_payments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_card_payments_updated_at BEFORE UPDATE ON card_payments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subscriptions_updated_at BEFORE UPDATE ON subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- DADOS INICIAIS (OPCIONAL)
-- =====================================================

-- Inserir configurações de pagamento (se necessário)
-- INSERT INTO payment_config (key, value) VALUES 
-- ('pix_key', 'slavosier298@gmail.com'),
-- ('monthly_price', '1.00'),
-- ('yearly_price', '2.00'); 