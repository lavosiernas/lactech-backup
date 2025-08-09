-- =====================================================
-- CORREÇÃO ESPECÍFICA PARA ERRO CREATE_INITIAL_FARM
-- Resolve: "Could not find the function public.create_initial_farm(...)"
-- =====================================================

-- 1. CORRIGIR CREATE_INITIAL_FARM - Parâmetros na ordem correta
DROP FUNCTION IF EXISTS create_initial_farm(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, INTEGER, DECIMAL, DECIMAL);

CREATE OR REPLACE FUNCTION create_initial_farm(
    p_name TEXT,
    p_owner_name TEXT,
    p_city TEXT DEFAULT NULL,
    p_state TEXT DEFAULT NULL,
    p_cnpj TEXT DEFAULT NULL,
    p_animal_count INTEGER DEFAULT 0,
    p_daily_production DECIMAL DEFAULT 0,
    p_total_area_hectares DECIMAL DEFAULT NULL,
    p_phone TEXT DEFAULT NULL,
    p_email TEXT DEFAULT NULL,
    p_address TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    farm_id UUID;
BEGIN
    INSERT INTO farms (
        name, owner_name, cnpj, city, state, address, phone, email,
        animal_count, daily_production, total_area_hectares,
        setup_completed, is_configured, is_active
    ) VALUES (
        p_name, p_owner_name, p_cnpj, p_city, p_state, p_address, p_phone, p_email,
        p_animal_count, p_daily_production, p_total_area_hectares,
        TRUE, TRUE, TRUE
    ) RETURNING id INTO farm_id;
    
    RETURN farm_id;
END;
$$;

-- 2. CORRIGIR CREATE_INITIAL_USER - Adicionar p_user_id como primeiro parâmetro
DROP FUNCTION IF EXISTS create_initial_user(UUID, TEXT, TEXT, TEXT, TEXT);

CREATE OR REPLACE FUNCTION create_initial_user(
    p_user_id UUID,
    p_farm_id UUID,
    p_name TEXT,
    p_email TEXT,
    p_role TEXT,
    p_whatsapp TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_id UUID;
BEGIN
    INSERT INTO users (
        id, farm_id, name, email, role, whatsapp, is_active
    ) VALUES (
        p_user_id, p_farm_id, p_name, p_email, p_role, p_whatsapp, TRUE
    ) RETURNING id INTO user_id;
    
    RETURN user_id;
END;
$$;

-- 3. ADICIONAR FUNÇÕES FALTANTES
-- GET_FARM_STATISTICS
CREATE OR REPLACE FUNCTION get_farm_statistics()
RETURNS TABLE (
    total_animals INTEGER,
    total_production DECIMAL,
    avg_daily_production DECIMAL,
    total_payments DECIMAL,
    recent_productions JSON
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(COUNT(DISTINCT a.id), 0)::INTEGER as total_animals,
        COALESCE(SUM(mp.volume_liters), 0)::DECIMAL as total_production,
        COALESCE(AVG(mp.volume_liters), 0)::DECIMAL as avg_daily_production,
        COALESCE(SUM(p.amount), 0)::DECIMAL as total_payments,
        COALESCE(
            (SELECT json_agg(
                json_build_object(
                    'date', mp2.production_date,
                    'volume', mp2.volume_liters,
                    'shift', mp2.shift
                )
            ) FROM milk_production mp2 
            WHERE mp2.farm_id IN (SELECT farm_id FROM users WHERE id = auth.uid())
            ORDER BY mp2.production_date DESC LIMIT 10
            ), '[]'::json
        ) as recent_productions
    FROM users u
    LEFT JOIN farms f ON u.farm_id = f.id
    LEFT JOIN animals a ON f.id = a.farm_id AND a.is_active = TRUE
    LEFT JOIN milk_production mp ON f.id = mp.farm_id
    LEFT JOIN payments p ON f.id = p.farm_id
    WHERE u.id = auth.uid();
END;
$$;

-- REGISTER_MILK_PRODUCTION
CREATE OR REPLACE FUNCTION register_milk_production(
    p_production_date DATE,
    p_shift VARCHAR(20),
    p_volume_liters DECIMAL(8,2),
    p_temperature DECIMAL(4,1) DEFAULT NULL,
    p_observations TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    production_id UUID;
    user_farm_id UUID;
BEGIN
    -- Obter farm_id do usuário logado
    SELECT farm_id INTO user_farm_id 
    FROM users 
    WHERE id = auth.uid();
    
    IF user_farm_id IS NULL THEN
        RAISE EXCEPTION 'Usuário não está associado a uma fazenda';
    END IF;
    
    -- Inserir produção de leite
    INSERT INTO milk_production (
        farm_id, user_id, production_date, shift, volume_liters, temperature, observations
    ) VALUES (
        user_farm_id, auth.uid(), p_production_date, p_shift, p_volume_liters, p_temperature, p_observations
    ) RETURNING id INTO production_id;
    
    RETURN production_id;
END;
$$;

-- =====================================================
-- CONFIRMAÇÃO
-- =====================================================

SELECT 'CORREÇÕES APLICADAS COM SUCESSO!' as status;
SELECT 'create_initial_farm corrigido' as info;
SELECT 'create_initial_user corrigido' as info;
SELECT 'get_farm_statistics adicionado' as info;
SELECT 'register_milk_production adicionado' as info; 