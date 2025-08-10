# 🚀 Passos para Configurar o Novo Banco LacTech

## 📋 **NOVO PROJETO SUPABASE**
- **URL**: `https://mauioyodoxmuzqweaasc.supabase.co`
- **Key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1hdWlveW9kb3htdXpxd2VhYXNjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ3NzYyNzksImV4cCI6MjA3MDM1MjI3OX0.m2nZ_5Vbi9aBz1vZ_oA-JHsd_yqD9brJXjnr39k7Ajc`

---

## 🔧 **PASSO 1: Executar Script SQL**

### 1.1 Acesse o Supabase Dashboard
```
https://supabase.com/dashboard/project/mauioyodoxmuzqweaasc
```

### 1.2 Vá para SQL Editor
- Menu lateral → **"SQL Editor"**
- Clique em **"New Query"**

### 1.3 Execute o Script Completo
- Copie **TODO** o conteúdo de `database-creation.sql`
- Cole no editor SQL
- Clique **"Run"** ou `Ctrl+Enter`

### 1.4 Verificar Resultado
Deve aparecer:
```
✅ LacTech database schema created successfully!
✅ Tables created: 11
✅ Functions created: 9
```

---

## 🧪 **PASSO 2: Testar Conexão**

### 2.1 No Console do Navegador (F12)
```javascript
// Teste básico
const { createClient } = supabase;
const client = createClient(
  'https://mauioyodoxmuzqweaasc.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1hdWlveW9kb3htdXpxd2VhYXNjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ3NzYyNzksImV4cCI6MjA3MDM1MjI3OX0.m2nZ_5Vbi9aBz1vZ_oA-JHsd_yqD9brJXjnr39k7Ajc'
);

// Testar tabelas
const { data, error } = await client.from('fazendas').select('count').limit(1);
console.log('Conexão:', error ? 'ERRO: ' + error.message : '✅ SUCESSO');
```

---

## 👤 **PASSO 3: Criar Primeira Fazenda**

### 3.1 Via Interface Web
- Acesse `PrimeiroAcesso.html`
- Preencha os dados da fazenda
- Crie o usuário proprietário

### 3.2 Via SQL (Alternativo)
```sql
-- 1. Criar fazenda
SELECT create_initial_farm(
    'Fazenda Teste',           -- nome
    '12.345.678/0001-90',      -- CNPJ
    '(11) 99999-9999',         -- telefone (opcional)
    'Rua Teste, 123',          -- endereço (opcional)
    'São Paulo',               -- cidade (opcional)
    'SP'                       -- estado (opcional)
);

-- 2. Verificar criação
SELECT * FROM fazendas WHERE nome_fazenda = 'Fazenda Teste';
```

---

## 🔍 **PASSO 4: Verificar Estrutura**

### 4.1 Verificar Tabelas
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;
```

**Deve retornar:**
- animais
- assinaturas  
- configuracoes_relatorios
- fazendas
- logs_atividades
- pagamentos
- pix_pagamentos
- producao_leite
- testes_qualidade
- tratamentos_veterinarios
- usuarios

### 4.2 Verificar Funções
```sql
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
ORDER BY routine_name;
```

**Deve retornar:**
- belongs_to_same_farm
- check_farm_exists
- check_user_exists
- complete_farm_setup
- create_initial_farm
- create_initial_user
- get_current_user_farm_id
- update_updated_at_column
- user_has_role

### 4.3 Verificar RLS
```sql
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public';
```

---

## ⚙️ **PASSO 5: Atualizar Frontend**

### 5.1 Configurações Já Atualizadas
- ✅ `supabase-config.js` - Nova configuração centralizada
- ✅ `gerente.js` - Nova URL/Key  
- ✅ `funcionario.js` - Nova URL/Key
- ✅ `login.js` - Nova URL/Key
- ✅ `primeiroAcesso.js` - Nova URL/Key

### 5.2 Testar Páginas
1. **Primeiro Acesso**: `PrimeiroAcesso.html`
2. **Login**: `login.html`
3. **Gerente**: `gerente.html`
4. **Funcionário**: `funcionario.html`

---

## 🚨 **Troubleshooting**

### Erro: "Tables not found"
```sql
-- Verificar se script executou completamente
SELECT COUNT(*) as total_tables 
FROM information_schema.tables 
WHERE table_schema = 'public';
-- Deve retornar: 11
```

### Erro: "Functions not found" 
```sql
-- Re-executar apenas seção de funções
-- (Copiar do script original apenas a parte de CREATE OR REPLACE FUNCTION)
```

### Erro: "Permission denied"
```sql
-- Verificar permissões
SELECT current_user, session_user;
-- Deve estar logado no Supabase correto
```

### Erro: "RLS blocking queries"
```sql
-- Temporariamente desabilitar RLS para teste
ALTER TABLE fazendas DISABLE ROW LEVEL SECURITY;
-- (Re-habilitar depois: ALTER TABLE fazendas ENABLE ROW LEVEL SECURITY;)
```

---

## ✅ **Checklist Final**

- [ ] Script SQL executado sem erros
- [ ] 11 tabelas criadas  
- [ ] 9 funções criadas
- [ ] RLS habilitado em todas as tabelas
- [ ] Conexão testada via console
- [ ] Primeira fazenda criada
- [ ] Login funcionando
- [ ] Redirecionamento por role OK

---

**🎯 Resultado Esperado:** Sistema 100% funcional com novo banco configurado!
