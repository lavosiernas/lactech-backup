# LacTech Database Setup Guide

## 📋 Guia Completo de Configuração do Banco de Dados

### 🎯 Visão Geral
Este é o script **reformulado e livre de erros** para criar todo o banco de dados do sistema LacTech no Supabase.

### 🚀 Como Executar

#### 1. Acesse o Supabase Dashboard
- Vá para [supabase.com](https://supabase.com)
- Faça login na sua conta
- Selecione seu projeto: `rvvydklrtcabdwixkjiz`

#### 2. Abra o SQL Editor
- No menu lateral, clique em **"SQL Editor"**
- Clique em **"New Query"**

#### 3. Execute o Script
- Copie todo o conteúdo do arquivo `database-creation.sql`
- Cole no editor SQL
- Clique em **"Run"** ou pressione `Ctrl+Enter`

#### 4. Verifique a Execução
O script deve executar sem erros e mostrar:
```
LacTech database schema created successfully!
Tables created: 11
Functions created: 9
```

### 📊 Estrutura Criada

#### **Tabelas Principais**
1. `fazendas` - Dados das fazendas
2. `usuarios` - Usuários do sistema
3. `animais` - Cadastro de animais
4. `producao_leite` - Registros de produção
5. `testes_qualidade` - Testes de qualidade do leite
6. `tratamentos_veterinarios` - Histórico veterinário
7. `pagamentos` - Controle financeiro
8. `pix_pagamentos` - Pagamentos PIX (assinaturas)
9. `assinaturas` - Planos de assinatura
10. `configuracoes_relatorios` - Settings de relatórios
11. `logs_atividades` - Auditoria do sistema

#### **Funções de Segurança (RLS)**
- `get_current_user_farm_id()` - Obtém fazenda do usuário atual
- `user_has_role(TEXT)` - Verifica role do usuário
- `belongs_to_same_farm(UUID)` - Verifica se pertence à mesma fazenda

#### **Funções de Setup**
- `check_farm_exists(TEXT, TEXT)` - Verifica se fazenda existe
- `check_user_exists(TEXT)` - Verifica se usuário existe
- `create_initial_farm(...)` - Cria fazenda inicial
- `create_initial_user(...)` - Cria usuário inicial
- `complete_farm_setup(...)` - Finaliza configuração

### 🔒 Segurança (RLS)

#### **Políticas Implementadas**
- **Isolamento por Fazenda**: Usuários só veem dados da própria fazenda
- **Controle de Acesso**: Diferentes permissões por cargo
- **Soft Delete**: Registros são marcados como deletados, não removidos
- **Auditoria**: Todas as ações são logadas

#### **Cargos Suportados**
- `proprietario` - Acesso total à fazenda
- `gerente` - Gerenciamento operacional
- `funcionario` - Registro de produção
- `veterinario` - Cuidados veterinários

### 📈 Novidades desta Versão

#### **✅ Problemas Corrigidos**
- Ordem correta de criação (tabelas → funções → políticas)
- Nomes padronizados em português
- Constraints bem definidas
- Indexes para performance
- RLS corretamente configurado
- Funções sem dependências circulares

#### **🆕 Melhorias**
- Nomenclatura clara e consistente
- Validações de dados aprimoradas
- Soft delete em todas as tabelas
- Logs de auditoria automáticos
- Configurações de relatório integradas
- Sistema de assinaturas PIX

### 🔧 Configuração Pós-Instalação

#### **1. Verificar Conectividade**
Execute no console do navegador:
```javascript
// Teste básico de conexão
const { data, error } = await supabase
  .from('fazendas')
  .select('count')
  .limit(1);

console.log('Conexão:', error ? 'ERRO' : 'OK');
```

#### **2. Criar Primeira Fazenda** 
Use a página `PrimeiroAcesso.html` ou execute:
```sql
-- Exemplo de criação manual
SELECT create_initial_farm(
  'Fazenda Exemplo',
  '12.345.678/0001-90',
  '(11) 99999-9999',
  'Rua Exemplo, 123',
  'São Paulo',
  'SP'
);
```

### 🚨 Troubleshooting

#### **Erro: "relation does not exist"**
- Certifique-se de executar o script completo
- Verifique se todas as tabelas foram criadas

#### **Erro: "permission denied"**
- Verifique se está logado no Supabase
- Confirme se o projeto está correto

#### **Erro: "function does not exist"**
- Execute novamente a seção de funções
- Verifique se não há erros de sintaxe

### 📞 Suporte
Se encontrar problemas:
1. Verifique os logs do Supabase
2. Execute o script por partes
3. Confirme as permissões do usuário
4. Teste a conectividade básica

---

**Status**: ✅ Testado e validado
**Versão**: 2.0 (Reformulada)
**Compatibilidade**: Supabase PostgreSQL 15+
