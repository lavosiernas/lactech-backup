-- =====================================================
-- VIEWS SEGURAS (SEM ALERTAS DE SEGURANÇA)
-- =====================================================

-- Remover views antigas que causam alertas
DROP VIEW IF EXISTS pending_payments;
DROP VIEW IF EXISTS active_subscriptions;

-- View para pagamentos pendentes (SEM expor emails)
CREATE VIEW pending_payments AS
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
WHERE p.status = 'pending';

-- View para assinaturas ativas (SEM expor emails)
CREATE VIEW active_subscriptions AS
SELECT 
    s.id,
    s.plan_type,
    s.amount,
    s.starts_at,
    s.expires_at,
    p.txid as payment_txid
FROM subscriptions s
LEFT JOIN pix_payments p ON s.payment_id = p.id
WHERE s.status = 'active' AND s.expires_at > NOW();

-- View para estatísticas de pagamentos (segura)
CREATE VIEW payment_stats AS
SELECT 
    COUNT(*) as total_payments,
    COUNT(CASE WHEN status = 'confirmed' THEN 1 END) as confirmed_payments,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_payments,
    COUNT(CASE WHEN status = 'expired' THEN 1 END) as expired_payments,
    SUM(CASE WHEN status = 'confirmed' THEN amount ELSE 0 END) as total_revenue
FROM pix_payments;

-- View para estatísticas de assinaturas (segura)
CREATE VIEW subscription_stats AS
SELECT 
    COUNT(*) as total_subscriptions,
    COUNT(CASE WHEN status = 'active' THEN 1 END) as active_subscriptions,
    COUNT(CASE WHEN plan_type = 'monthly' THEN 1 END) as monthly_subscriptions,
    COUNT(CASE WHEN plan_type = 'yearly' THEN 1 END) as yearly_subscriptions
FROM subscriptions;

-- =====================================================
-- FUNÇÕES SEGURAS PARA CONSULTAS
-- =====================================================

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

-- =====================================================
-- VERIFICAÇÃO DE SEGURANÇA
-- =====================================================

-- Verificar se as views foram criadas corretamente
SELECT 
    schemaname,
    tablename,
    tabletype
FROM pg_tables 
WHERE tablename IN ('pending_payments', 'active_subscriptions', 'payment_stats', 'subscription_stats')
   OR tablename LIKE '%pix%' 
   OR tablename LIKE '%subscription%';

-- Verificar se as funções foram criadas
SELECT 
    proname,
    prosrc
FROM pg_proc 
WHERE proname IN ('get_user_payments', 'get_user_subscriptions');
