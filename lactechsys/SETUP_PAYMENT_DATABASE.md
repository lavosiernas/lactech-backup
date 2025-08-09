# 🔧 Configuração do Banco de Dados de Pagamentos - LacTech

## 📋 Visão Geral

Este documento contém as instruções para configurar o banco de dados de pagamentos no Supabase. O sistema utiliza um banco separado do sistema principal para gerenciar pagamentos PIX, assinaturas e transações.

## 🔑 Informações do Banco

- **URL:** `https://tnnuiqghomibpsvqewmt.supabase.co`
- **Anon Key:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
- **Finalidade:** Sistema de pagamentos e assinaturas

## 🚀 Configuração Automática

### Opção 1: Interface Web (Recomendado)

1. Abra o arquivo `setup_payment_db.html` no navegador
2. Execute as etapas na ordem:
   - **Etapa 1:** Testar conexão com o Supabase
   - **Etapa 2:** Gerar SQL das tabelas
   - **Etapa 3:** Verificar tabelas existentes
3. Copie o SQL gerado e execute no Supabase SQL Editor

### Opção 2: SQL Direto

1. Acesse o [Supabase Dashboard](https://app.supabase.com/)
2. Vá para o projeto de pagamentos
3. Abra o **SQL Editor**
4. Execute o conteúdo do arquivo `complete_payment_setup.sql`

## 📊 Estrutura do Banco

### Tabelas Principais

#### 1. `pix_payments` - Pagamentos PIX
```sql
- id: UUID (Primary Key)
- user_id: UUID (Foreign Key -> auth.users)
- txid: TEXT (Unique) - Identificador único da transação
- amount: DECIMAL(10,2) - Valor do pagamento
- status: TEXT - (pending, confirmed, expired, cancelled)
- pix_key: TEXT - Chave PIX para recebimento
- pix_key_type: TEXT - Tipo da chave (email, cpf, telefone, aleatoria)
- created_at: TIMESTAMP
- updated_at: TIMESTAMP
- expires_at: TIMESTAMP - Data de expiração do pagamento
```

#### 2. `card_payments` - Pagamentos com Cartão
```sql
- id: UUID (Primary Key)
- user_id: UUID (Foreign Key -> auth.users)
- payment_intent_id: TEXT (Unique)
- amount: DECIMAL(10,2)
- status: TEXT - (pending, confirmed, failed, cancelled)
- payment_method: TEXT - (card, pix)
- card_last4: TEXT - Últimos 4 dígitos do cartão
- card_brand: TEXT - Bandeira do cartão
- created_at: TIMESTAMP
- updated_at: TIMESTAMP
```

#### 3. `subscriptions` - Assinaturas
```sql
- id: UUID (Primary Key)
- user_id: UUID (Foreign Key -> auth.users)
- payment_id: UUID - ID do pagamento relacionado
- payment_type: TEXT - (pix, card)
- status: TEXT - (active, expired, cancelled)
- plan_type: TEXT - (monthly, yearly)
- amount: DECIMAL(10,2)
- starts_at: TIMESTAMP - Data de início
- expires_at: TIMESTAMP - Data de expiração
- created_at: TIMESTAMP
- updated_at: TIMESTAMP
```

#### 4. `payment_settings` - Configurações
```sql
- id: UUID (Primary Key)
- key: TEXT (Unique) - Chave da configuração
- value: TEXT - Valor da configuração
- description: TEXT - Descrição
- created_at: TIMESTAMP
- updated_at: TIMESTAMP
```

### Configurações Padrão

O sistema será configurado com os seguintes valores:

- **Chave PIX:** `slavosier298@gmail.com`
- **Preço Mensal:** R$ 1,00 (teste)
- **Preço Anual:** R$ 2,00 (teste)
- **Timeout de Pagamento:** 30 minutos

## 🔒 Segurança (RLS)

O sistema implementa **Row Level Security** para garantir que:

- Usuários só podem ver seus próprios pagamentos
- Usuários só podem criar pagamentos para si mesmos
- Usuários só podem atualizar seus próprios dados
- Todas as tabelas têm políticas de segurança ativas

## 🔧 Arquivos de Configuração

### Scripts JavaScript

1. **`payment_supabase_config.js`** - Configuração do cliente Supabase
2. **`pix_payment_system.js`** - Sistema completo de pagamentos PIX
3. **`setup_payment_db.html`** - Interface para configuração do banco

### Scripts SQL

1. **`payment_tables.sql`** - Definições das tabelas (referência)
2. **`complete_payment_setup.sql`** - Script completo de configuração

## ✅ Verificação da Instalação

Após executar a configuração, verifique se:

1. ✅ Todas as 4 tabelas foram criadas
2. ✅ Índices estão aplicados
3. ✅ Políticas RLS estão ativas
4. ✅ Triggers estão funcionando
5. ✅ Configurações padrão foram inseridas

## 🧪 Teste do Sistema

1. Abra `payment.html` no navegador
2. O sistema deve:
   - Conectar automaticamente ao banco de pagamentos
   - Gerar QR Code PIX
   - Mostrar opções de pagamento
   - Permitir verificação de status

## 🔄 Manutenção

### Limpeza de Pagamentos Expirados

Execute periodicamente:
```sql
SELECT expire_old_payments();
```

### Monitoramento de Assinaturas

Verifique assinaturas ativas:
```sql
SELECT COUNT(*) FROM subscriptions WHERE status = 'active';
```

## 🆘 Troubleshooting

### Problema: Tabelas não encontradas
**Solução:** Execute o SQL de configuração no Supabase SQL Editor

### Problema: Erro de conexão
**Solução:** Verifique se as credenciais do Supabase estão corretas

### Problema: RLS bloqueando acesso
**Solução:** Verifique se o usuário está autenticado corretamente

### Problema: QR Code não aparece
**Solução:** Verifique se a biblioteca QRCode.js está carregada

## 📞 Suporte

Em caso de problemas:

1. Verifique o console do navegador para erros
2. Confirme se todas as dependências estão carregadas
3. Teste a conexão com o Supabase
4. Verifique se as tabelas foram criadas corretamente

---

**✨ Sistema configurado com sucesso! O LacTech agora possui um sistema de pagamentos completo e seguro.**