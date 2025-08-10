-- ========================================
-- LACTECH - BANCO REFORMULADO COMPLETO
-- Criação limpa do banco com RLS robusto
-- Nomes em português, sem erros
-- ========================================

-- Limpar banco existente
DROP TABLE IF EXISTS public.producao_leite CASCADE;
DROP TABLE IF EXISTS public.animais CASCADE;
DROP TABLE IF EXISTS public.usuarios CASCADE;
DROP TABLE IF EXISTS public.fazendas CASCADE;

-- Remover funções existentes
DROP FUNCTION IF EXISTS public.check_farm_exists CASCADE;
DROP FUNCTION IF EXISTS public.check_user_exists CASCADE;
DROP FUNCTION IF EXISTS public.create_initial_farm CASCADE;
DROP FUNCTION IF EXISTS public.create_initial_user CASCADE;
DROP FUNCTION IF EXISTS public.complete_farm_setup CASCADE;

-- ========================================
-- 1. TABELA FAZENDAS
-- ========================================
CREATE TABLE public.fazendas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome TEXT NOT NULL,
    cnpj TEXT UNIQUE,
    proprietario_nome TEXT,
    telefone TEXT,
    email TEXT,
    endereco TEXT,
    hectares DECIMAL(10,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ========================================
-- 2. TABELA USUÁRIOS
-- ========================================
CREATE TABLE public.usuarios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    fazenda_id UUID REFERENCES public.fazendas(id) ON DELETE CASCADE,
    nome TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    telefone TEXT,
    funcao TEXT CHECK (funcao IN ('gerente', 'funcionario', 'veterinario', 'proprietario')) NOT NULL,
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ========================================
-- 3. TABELA ANIMAIS
-- ========================================
CREATE TABLE public.animais (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fazenda_id UUID REFERENCES public.fazendas(id) ON DELETE CASCADE,
    brinco TEXT NOT NULL,
    nome TEXT,
    raca TEXT,
    data_nascimento DATE,
    peso DECIMAL(8,2),
    status TEXT CHECK (status IN ('ativo', 'seco', 'vendido', 'morto')) DEFAULT 'ativo',
    observacoes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(fazenda_id, brinco)
);

-- ========================================
-- 4. TABELA PRODUÇÃO DE LEITE
-- ========================================
CREATE TABLE public.producao_leite (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fazenda_id UUID REFERENCES public.fazendas(id) ON DELETE CASCADE,
    animal_id UUID REFERENCES public.animais(id) ON DELETE CASCADE,
    data_producao DATE NOT NULL,
    periodo TEXT CHECK (periodo IN ('manha', 'tarde', 'noite')) NOT NULL,
    volume DECIMAL(8,2) NOT NULL CHECK (volume >= 0),
    temperatura DECIMAL(4,1),
    qualidade TEXT CHECK (qualidade IN ('A', 'B', 'C', 'Rejeitado')) DEFAULT 'A',
    observacoes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(animal_id, data_producao, periodo)
);

-- ========================================
-- 5. TRIGGERS PARA UPDATED_AT
-- ========================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_fazendas_updated_at BEFORE UPDATE ON public.fazendas FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_usuarios_updated_at BEFORE UPDATE ON public.usuarios FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_animais_updated_at BEFORE UPDATE ON public.animais FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_producao_leite_updated_at BEFORE UPDATE ON public.producao_leite FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ========================================
-- 6. ÍNDICES PARA PERFORMANCE
-- ========================================
CREATE INDEX idx_usuarios_auth_id ON public.usuarios(auth_id);
CREATE INDEX idx_usuarios_fazenda_id ON public.usuarios(fazenda_id);
CREATE INDEX idx_animais_fazenda_id ON public.animais(fazenda_id);
CREATE INDEX idx_animais_brinco ON public.animais(brinco);
CREATE INDEX idx_producao_fazenda_id ON public.producao_leite(fazenda_id);
CREATE INDEX idx_producao_animal_id ON public.producao_leite(animal_id);
CREATE INDEX idx_producao_data ON public.producao_leite(data_producao);

-- ========================================
-- 7. ROW LEVEL SECURITY (RLS)
-- ========================================

-- Habilitar RLS
ALTER TABLE public.fazendas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.animais ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.producao_leite ENABLE ROW LEVEL SECURITY;

-- Função auxiliar para obter fazenda do usuário atual
CREATE OR REPLACE FUNCTION auth.get_user_farm_id()
RETURNS UUID
LANGUAGE SQL
SECURITY DEFINER
AS $$
  SELECT fazenda_id FROM public.usuarios WHERE auth_id = auth.uid() AND ativo = true LIMIT 1;
$$;

-- POLÍTICAS RLS PARA FAZENDAS
CREATE POLICY "Usuários podem ver apenas sua fazenda" ON public.fazendas
    FOR SELECT USING (id = auth.get_user_farm_id());

CREATE POLICY "Usuários podem atualizar apenas sua fazenda" ON public.fazendas
    FOR UPDATE USING (id = auth.get_user_farm_id());

-- POLÍTICAS RLS PARA USUÁRIOS
CREATE POLICY "Usuários podem ver colegas da mesma fazenda" ON public.usuarios
    FOR SELECT USING (fazenda_id = auth.get_user_farm_id());

CREATE POLICY "Gerentes podem gerenciar usuários da fazenda" ON public.usuarios
    FOR ALL USING (
        fazenda_id = auth.get_user_farm_id() AND
        EXISTS (
            SELECT 1 FROM public.usuarios 
            WHERE auth_id = auth.uid() 
            AND funcao = 'gerente' 
            AND ativo = true
        )
    );

-- POLÍTICAS RLS PARA ANIMAIS
CREATE POLICY "Usuários podem ver animais da fazenda" ON public.animais
    FOR SELECT USING (fazenda_id = auth.get_user_farm_id());

CREATE POLICY "Usuários podem gerenciar animais da fazenda" ON public.animais
    FOR ALL USING (fazenda_id = auth.get_user_farm_id());

-- POLÍTICAS RLS PARA PRODUÇÃO
CREATE POLICY "Usuários podem ver produção da fazenda" ON public.producao_leite
    FOR SELECT USING (fazenda_id = auth.get_user_farm_id());

CREATE POLICY "Usuários podem gerenciar produção da fazenda" ON public.producao_leite
    FOR ALL USING (fazenda_id = auth.get_user_farm_id());

-- ========================================
-- 8. FUNÇÕES RPC PARA FRONTEND
-- ========================================

-- Verificar se fazenda existe
CREATE OR REPLACE FUNCTION public.check_farm_exists(p_nome TEXT, p_cnpj TEXT DEFAULT NULL)
RETURNS BOOLEAN
LANGUAGE SQL
SECURITY DEFINER
AS $$
  SELECT EXISTS(
    SELECT 1 FROM public.fazendas 
    WHERE nome = p_nome 
    OR (p_cnpj IS NOT NULL AND cnpj = p_cnpj)
  );
$$;

-- Verificar se usuário existe
CREATE OR REPLACE FUNCTION public.check_user_exists(p_email TEXT)
RETURNS BOOLEAN
LANGUAGE SQL
SECURITY DEFINER
AS $$
  SELECT EXISTS(
    SELECT 1 FROM public.usuarios 
    WHERE email = p_email
  );
$$;

-- Criar fazenda inicial (apenas para novos usuários)
CREATE OR REPLACE FUNCTION public.create_initial_farm(
    p_nome TEXT,
    p_cnpj TEXT DEFAULT NULL,
    p_proprietario_nome TEXT DEFAULT NULL,
    p_telefone TEXT DEFAULT NULL,
    p_email TEXT DEFAULT NULL,
    p_endereco TEXT DEFAULT NULL,
    p_hectares DECIMAL DEFAULT NULL
)
RETURNS UUID
LANGUAGE PLPGSQL
SECURITY DEFINER
AS $$
DECLARE
    farm_id UUID;
BEGIN
    -- Verificar se usuário já não tem fazenda
    IF auth.get_user_farm_id() IS NOT NULL THEN
        RAISE EXCEPTION 'Usuário já possui fazenda';
    END IF;
    
    -- Criar fazenda
    INSERT INTO public.fazendas (nome, cnpj, proprietario_nome, telefone, email, endereco, hectares)
    VALUES (p_nome, p_cnpj, p_proprietario_nome, p_telefone, p_email, p_endereco, p_hectares)
    RETURNING id INTO farm_id;
    
    RETURN farm_id;
END;
$$;

-- Criar usuário inicial
CREATE OR REPLACE FUNCTION public.create_initial_user(
    p_fazenda_id UUID,
    p_nome TEXT,
    p_email TEXT,
    p_telefone TEXT DEFAULT NULL,
    p_funcao TEXT DEFAULT 'gerente'
)
RETURNS UUID
LANGUAGE PLPGSQL
SECURITY DEFINER
AS $$
DECLARE
    user_id UUID;
BEGIN
    -- Criar usuário
    INSERT INTO public.usuarios (auth_id, fazenda_id, nome, email, telefone, funcao)
    VALUES (auth.uid(), p_fazenda_id, p_nome, p_email, p_telefone, p_funcao)
    RETURNING id INTO user_id;
    
    RETURN user_id;
END;
$$;

-- Setup completo inicial
CREATE OR REPLACE FUNCTION public.complete_farm_setup(
    p_farm_nome TEXT,
    p_farm_cnpj TEXT DEFAULT NULL,
    p_farm_proprietario TEXT DEFAULT NULL,
    p_farm_telefone TEXT DEFAULT NULL,
    p_farm_email TEXT DEFAULT NULL,
    p_farm_endereco TEXT DEFAULT NULL,
    p_farm_hectares DECIMAL DEFAULT NULL,
    p_user_nome TEXT,
    p_user_email TEXT,
    p_user_telefone TEXT DEFAULT NULL,
    p_user_funcao TEXT DEFAULT 'gerente'
)
RETURNS JSONB
LANGUAGE PLPGSQL
SECURITY DEFINER
AS $$
DECLARE
    farm_id UUID;
    user_id UUID;
    result JSONB;
BEGIN
    -- Criar fazenda
    farm_id := public.create_initial_farm(
        p_farm_nome, p_farm_cnpj, p_farm_proprietario, 
        p_farm_telefone, p_farm_email, p_farm_endereco, p_farm_hectares
    );
    
    -- Criar usuário
    user_id := public.create_initial_user(
        farm_id, p_user_nome, p_user_email, p_user_telefone, p_user_funcao
    );
    
    -- Retornar resultado
    result := jsonb_build_object(
        'fazenda_id', farm_id,
        'usuario_id', user_id,
        'success', true
    );
    
    RETURN result;
END;
$$;

-- ========================================
-- 9. DADOS DE TESTE (OPCIONAL)
-- ========================================

-- Inserir fazenda de exemplo
INSERT INTO public.fazendas (nome, cnpj, proprietario_nome, telefone, email, endereco, hectares)
VALUES ('Fazenda São João', '12.345.678/0001-90', 'João Silva', '(11) 99999-9999', 'joao@fazenda.com', 'Rural, São Paulo, SP', 50.00);

-- ========================================
-- EXECUÇÃO CONCLUÍDA
-- ========================================

-- Mensagem de sucesso
DO $$
BEGIN
    RAISE NOTICE '✅ BANCO LACTECH REFORMULADO CRIADO COM SUCESSO!';
    RAISE NOTICE '📊 Tabelas: fazendas, usuarios, animais, producao_leite';
    RAISE NOTICE '🔒 RLS ativado com políticas robustas';
    RAISE NOTICE '⚡ Índices criados para performance';
    RAISE NOTICE '🔧 Funções RPC disponíveis para frontend';
END $$;

