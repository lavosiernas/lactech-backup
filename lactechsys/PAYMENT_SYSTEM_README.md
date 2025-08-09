# Sistema de Pagamento Pix - LacTech

## 📋 Visão Geral

Sistema completo de verificação automática de pagamento via Pix usando Supabase e JavaScript. O sistema gera QR Codes Pix, monitora pagamentos e gerencia assinaturas automaticamente.

## 🚀 Funcionalidades

### ✅ Implementadas
- **Geração de QR Code Pix** com identificador único
- **Verificação automática** de status de pagamento
- **Gestão de assinaturas** (ativação/expiração)
- **Interface responsiva** com Tailwind CSS
- **Sistema de notificações** em tempo real
- **Contador regressivo** para expiração
- **Validações de segurança** e proteção contra spam
- **Configuração flexível** por ambiente

### 🔄 Para Implementação Futura
- **Integração com APIs bancárias** (Inter, Gerencianet, etc.)
- **Webhooks de confirmação** automática
- **Sistema de retry** para pagamentos falhados
- **Relatórios de pagamento** detalhados
- **Múltiplos métodos de pagamento**

## 📁 Estrutura de Arquivos

```
lactechsys/
├── pix_payment_system.js      # Sistema principal de pagamento
├── payment.html               # Página de pagamento
├── payment_config.js          # Configurações do sistema
├── PAYMENT_SYSTEM_README.md   # Esta documentação
└── SQL/
    └── payment_tables.sql     # Scripts SQL para Supabase
```

## 🗄️ Estrutura do Banco de Dados

### Tabela: `pix_payments`
```sql
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
```

### Tabela: `subscriptions`
```sql
CREATE TABLE subscriptions (
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
```

## ⚙️ Configuração

### 1. Configurar Supabase
```sql
-- Executar no SQL Editor do Supabase
-- Copiar e executar o conteúdo de payment_tables.sql
```

### 2. Configurar Chave Pix
```javascript
// Em payment_config.js
const PAYMENT_CONFIG = {
    PIX_KEY: 'sua-chave-pix@email.com', // Sua chave Pix
    PIX_KEY_TYPE: 'email', // Tipo da chave
    // ... outras configurações
};
```

### 3. Integrar no Sistema
```html
<!-- Adicionar em qualquer página que precise verificar assinatura -->
<script src="pix_payment_system.js"></script>
<script>
    // Verificar assinatura antes de permitir acesso
    const pixSystem = new PixPaymentSystem();
    await pixSystem.initialize();
</script>
```

## 🔄 Fluxo de Funcionamento

### 1. **Verificação de Assinatura**
```javascript
// Ao fazer login, o sistema verifica:
- Se o usuário tem assinatura ativa
- Se a assinatura não expirou
- Se precisa renovar
```

### 2. **Geração de Pagamento**
```javascript
// Se não há assinatura ativa:
- Gera QR Code Pix com txid único
- Cria registro de pagamento pendente
- Mostra interface de pagamento
```

### 3. **Monitoramento de Pagamento**
```javascript
// Sistema verifica automaticamente:
- Status do pagamento a cada 10 segundos
- Expiração do QR Code (30 minutos)
- Confirmação via Supabase
```

### 4. **Ativação de Assinatura**
```javascript
// Quando pagamento é confirmado:
- Atualiza status do pagamento
- Cria/atualiza assinatura
- Libera acesso ao sistema
```

## 🛡️ Segurança

### Proteções Implementadas
- **Rate Limiting**: Máximo 5 tentativas por hora
- **Bloqueio Temporário**: 1 hora após muitas tentativas
- **Validação de Valores**: Apenas valores predefinidos
- **RLS (Row Level Security)**: Usuários só veem seus dados
- **Validação de Chaves Pix**: Formato correto por tipo

### Validações
```javascript
// Exemplo de validação
PaymentSecurity.validatePaymentRequest(userId, amount);
PaymentUtils.validatePixKey(key, type);
```

## 🎨 Interface do Usuário

### Estados da Interface
1. **Loading**: Verificando assinatura
2. **Payment Screen**: QR Code e instruções
3. **Active Subscription**: Acesso liberado
4. **Error**: Problemas ou expiração

### Componentes
- **QR Code Generator**: Gera QR Code Pix
- **Countdown Timer**: Tempo restante para pagamento
- **Notification System**: Feedback em tempo real
- **Copy Button**: Copiar chave Pix
- **Payment Status**: Verificação manual

## 🔧 Configurações Avançadas

### Ambientes
```javascript
// Development
ENVIRONMENT: 'development'
DEBUG_MODE: true
PAYMENT_CHECK_INTERVAL: 5000

// Production
ENVIRONMENT: 'production'
DEBUG_MODE: false
PAYMENT_CHECK_INTERVAL: 15000
```

### Personalização
```javascript
// Preços
MONTHLY_PRICE: 29.90
YEARLY_PRICE: 299.90

// Tempos
PAYMENT_TIMEOUT: 30 * 60 * 1000 // 30 minutos
SUBSCRIPTION_DURATION: 30 // dias

// Segurança
MAX_PAYMENT_ATTEMPTS: 5
BLOCK_DURATION: 60 * 60 * 1000 // 1 hora
```

## 📊 Monitoramento e Logs

### Logs Disponíveis
```javascript
PaymentUtils.log('Mensagem', 'info|success|warning|error');
```

### Métricas Importantes
- Pagamentos gerados
- Pagamentos confirmados
- Taxa de conversão
- Tempo médio de pagamento
- Assinaturas ativas/expiradas

## 🔄 Integração Futura

### APIs Bancárias
```javascript
// Exemplo de integração com API bancária
const bankAPI = {
    checkPayment: async (txid) => {
        // Integração com API do banco
        return await fetch('/api/bank/check-payment', {
            method: 'POST',
            body: JSON.stringify({ txid })
        });
    }
};
```

### Webhooks
```javascript
// Webhook para confirmação automática
app.post('/webhook/pix-confirmation', (req, res) => {
    const { txid, status } = req.body;
    // Atualizar status no Supabase
    supabase.from('pix_payments')
        .update({ status: 'confirmed' })
        .eq('txid', txid);
});
```

## 🚨 Troubleshooting

### Problemas Comuns

1. **QR Code não gera**
   - Verificar biblioteca QRCode
   - Verificar formato EMV
   - Verificar console para erros

2. **Pagamento não confirma**
   - Verificar chave Pix
   - Verificar txid único
   - Verificar logs de verificação

3. **Assinatura não ativa**
   - Verificar tabela subscriptions
   - Verificar RLS policies
   - Verificar logs de ativação

### Debug Mode
```javascript
// Ativar logs detalhados
PAYMENT_CONFIG.DEBUG_MODE = true;
```

## 📝 Exemplo de Uso

### Página de Pagamento
```html
<!DOCTYPE html>
<html>
<head>
    <script src="pix_payment_system.js"></script>
</head>
<body>
    <div id="payment-container"></div>
    <script>
        const pixSystem = new PixPaymentSystem();
        pixSystem.initialize();
    </script>
</body>
</html>
```

### Verificação de Acesso
```javascript
// Em qualquer página protegida
async function checkAccess() {
    const pixSystem = new PixPaymentSystem();
    await pixSystem.initialize();
    
    if (pixSystem.subscriptionStatus !== 'active') {
        window.location.href = 'payment.html';
    }
}
```

## 🔗 Links Úteis

- [Documentação Supabase](https://supabase.com/docs)
- [Especificação Pix](https://www.bcb.gov.br/novopix)
- [QR Code Generator](https://github.com/soldair/node-qrcode)
- [Tailwind CSS](https://tailwindcss.com/)

## 📞 Suporte

Para dúvidas ou problemas:
1. Verificar logs no console do navegador
2. Verificar configurações em `payment_config.js`
3. Verificar estrutura do banco no Supabase
4. Testar em modo debug

---

**Desenvolvido para LacTech Sistema Leiteiro** 🐄 