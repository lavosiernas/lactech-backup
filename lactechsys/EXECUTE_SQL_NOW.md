# 🚨 AÇÃO NECESSÁRIA - Configurar Banco de Pagamentos

## ⚡ Execute AGORA no Supabase

O sistema de pagamento está configurado, mas as **tabelas ainda não foram criadas** no banco de dados.

### 📋 Passos Rápidos:

1. **Acesse:** https://app.supabase.com/
2. **Selecione o projeto:** `tnnuiqghomibpsvqewmt`
3. **Vá para:** SQL Editor (menu lateral)
4. **Cole e execute** o SQL abaixo:

```sql
-- CONFIGURAÇÃO COMPLETA DO BANCO DE PAGAMENTOS
-- Execute este bloco completo de uma vez

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
        RAISE NOTICE 'Tabela pix_payments criada!';
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
        RAISE NOTICE 'Tabela subscriptions criada!';
    END IF;
END $$;

-- Habilitar RLS
ALTER TABLE pix_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- Políticas de segurança
CREATE POLICY IF NOT EXISTS "Users can manage their own pix payments" ON pix_payments
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY IF NOT EXISTS "Users can manage their own subscriptions" ON subscriptions
    FOR ALL USING (auth.uid() = user_id);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_pix_payments_user_id ON pix_payments(user_id);
CREATE INDEX IF NOT EXISTS idx_pix_payments_txid ON pix_payments(txid);
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON subscriptions(user_id);

-- Configurações
SELECT 'CONFIGURAÇÃO CONCLUÍDA! ✅' as status;
```

## ✅ Após Executar o SQL:

1. Recarregue a página `payment.html`
2. O sistema deve funcionar normalmente
3. QR Code PIX será gerado
4. Pagamentos serão salvos no banco

## 🔍 Verificar se Funcionou:

Execute no SQL Editor:
```sql
SELECT table_name FROM information_schema.tables 
WHERE table_name IN ('pix_payments', 'subscriptions');
```

Deve retornar 2 tabelas.

---

**🚀 Pronto! Após executar, o sistema estará 100% funcional.**