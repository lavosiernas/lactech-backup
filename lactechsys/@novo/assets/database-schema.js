// Database schema and table definitions for LacTech system

// New standardized table names (snake_case, clear naming)
export const TABLES = {
    // Core tables
    FAZENDAS: 'fazendas',
    USUARIOS: 'usuarios', 
    ANIMAIS: 'animais',
    
    // Production tables
    PRODUCAO_LEITE: 'producao_leite',
    TESTES_QUALIDADE: 'testes_qualidade',
    TRATAMENTOS_VETERINARIOS: 'tratamentos_veterinarios',
    
    // Financial tables
    PAGAMENTOS: 'pagamentos',
    ASSINATURAS: 'assinaturas',
    PIX_PAGAMENTOS: 'pix_pagamentos',
    
    // System tables
    CONFIGURACOES_RELATORIOS: 'configuracoes_relatorios',
    LOGS_ATIVIDADES: 'logs_atividades'
};

// Standardized column names
export const COLUMNS = {
    // Common columns
    ID: 'id',
    CREATED_AT: 'criado_em',
    UPDATED_AT: 'atualizado_em',
    DELETED_AT: 'deletado_em',
    
    // User columns
    USER_ID: 'usuario_id',
    FARM_ID: 'fazenda_id',
    ANIMAL_ID: 'animal_id',
    
    // Farm columns
    FARM_NAME: 'nome_fazenda',
    FARM_CNPJ: 'cnpj',
    FARM_PHONE: 'telefone',
    FARM_ADDRESS: 'endereco',
    FARM_CITY: 'cidade',
    FARM_STATE: 'estado',
    
    // User columns
    USER_NAME: 'nome',
    USER_EMAIL: 'email',
    USER_ROLE: 'cargo',
    USER_ACTIVE: 'ativo',
    USER_PHONE: 'telefone',
    USER_PHOTO: 'foto_perfil',
    
    // Animal columns
    ANIMAL_NAME: 'nome',
    ANIMAL_BREED: 'raca',
    ANIMAL_BIRTH_DATE: 'data_nascimento',
    ANIMAL_TAG: 'brinco',
    ANIMAL_WEIGHT: 'peso',
    ANIMAL_STATUS: 'status',
    
    // Production columns
    PRODUCTION_DATE: 'data_producao',
    PRODUCTION_TIME: 'hora_producao',
    VOLUME_LITERS: 'volume_litros',
    SHIFT: 'turno',
    TEMPERATURE: 'temperatura',
    OBSERVATIONS: 'observacoes',
    
    // Quality columns
    TEST_DATE: 'data_teste',
    FAT_PERCENTAGE: 'percentual_gordura',
    PROTEIN_PERCENTAGE: 'percentual_proteina',
    SOMATIC_CELL_COUNT: 'contagem_celulas_somaticas',
    TOTAL_BACTERIAL_COUNT: 'contagem_bacterias_totais',
    
    // Payment columns
    PAYMENT_DATE: 'data_pagamento',
    GROSS_AMOUNT: 'valor_bruto',
    NET_AMOUNT: 'valor_liquido',
    PAYMENT_STATUS: 'status_pagamento',
    PAYMENT_METHOD: 'metodo_pagamento',
    
    // Treatment columns
    TREATMENT_DATE: 'data_tratamento',
    TREATMENT_TYPE: 'tipo_tratamento',
    MEDICATION: 'medicamento',
    DOSAGE: 'dosagem',
    VETERINARIAN: 'veterinario',
    HEALTH_STATUS: 'status_saude'
};

// Standard query patterns
export const QUERY_PATTERNS = {
    // Basic CRUD operations
    SELECT_ALL: (table, farmId) => ({
        table,
        select: '*',
        eq: [COLUMNS.FARM_ID, farmId],
        order: [COLUMNS.CREATED_AT, { ascending: false }]
    }),
    
    SELECT_BY_ID: (table, id) => ({
        table,
        select: '*',
        eq: [COLUMNS.ID, id],
        single: true
    }),
    
    INSERT: (table, data) => ({
        table,
        insert: data
    }),
    
    UPDATE: (table, id, data) => ({
        table,
        update: data,
        eq: [COLUMNS.ID, id]
    }),
    
    SOFT_DELETE: (table, id) => ({
        table,
        update: { [COLUMNS.DELETED_AT]: new Date().toISOString() },
        eq: [COLUMNS.ID, id]
    }),
    
    // Specific queries
    USERS_BY_FARM: (farmId) => ({
        table: TABLES.USUARIOS,
        select: '*',
        eq: [COLUMNS.FARM_ID, farmId],
        is: [COLUMNS.DELETED_AT, null],
        order: [COLUMNS.USER_NAME, { ascending: true }]
    }),
    
    PRODUCTION_BY_DATE_RANGE: (farmId, startDate, endDate) => ({
        table: TABLES.PRODUCAO_LEITE,
        select: `
            *,
            ${TABLES.USUARIOS}(${COLUMNS.USER_NAME})
        `,
        eq: [COLUMNS.FARM_ID, farmId],
        gte: [COLUMNS.PRODUCTION_DATE, startDate],
        lte: [COLUMNS.PRODUCTION_DATE, endDate],
        order: [COLUMNS.PRODUCTION_DATE, { ascending: false }]
    }),
    
    ANIMALS_ACTIVE: (farmId) => ({
        table: TABLES.ANIMAIS,
        select: '*',
        eq: [COLUMNS.FARM_ID, farmId],
        neq: [COLUMNS.ANIMAL_STATUS, 'descartado'],
        is: [COLUMNS.DELETED_AT, null],
        order: [COLUMNS.ANIMAL_NAME, { ascending: true }]
    })
};

// RLS (Row Level Security) helper functions
export const RLS_FUNCTIONS = {
    // Get current user's farm_id
    CURRENT_USER_FARM: `
        CREATE OR REPLACE FUNCTION get_current_user_farm_id()
        RETURNS UUID AS $$
        BEGIN
            RETURN (
                SELECT fazenda_id 
                FROM usuarios 
                WHERE id = auth.uid() 
                AND deletado_em IS NULL
            );
        END;
        $$ LANGUAGE plpgsql SECURITY DEFINER;
    `,
    
    // Check if user has specific role
    USER_HAS_ROLE: `
        CREATE OR REPLACE FUNCTION user_has_role(required_role TEXT)
        RETURNS BOOLEAN AS $$
        BEGIN
            RETURN EXISTS(
                SELECT 1 
                FROM usuarios 
                WHERE id = auth.uid() 
                AND cargo = required_role 
                AND ativo = true
                AND deletado_em IS NULL
            );
        END;
        $$ LANGUAGE plpgsql SECURITY DEFINER;
    `,
    
    // Check if user belongs to same farm
    SAME_FARM: `
        CREATE OR REPLACE FUNCTION belongs_to_same_farm(target_farm_id UUID)
        RETURNS BOOLEAN AS $$
        BEGIN
            RETURN target_farm_id = get_current_user_farm_id();
        END;
        $$ LANGUAGE plpgsql SECURITY DEFINER;
    `
};

// Standard RLS policies
export const RLS_POLICIES = {
    FARM_ISOLATION: (table) => `
        CREATE POLICY "farm_isolation_${table}" ON ${table}
        FOR ALL USING (belongs_to_same_farm(fazenda_id));
    `,
    
    MANAGER_ONLY: (table) => `
        CREATE POLICY "manager_only_${table}" ON ${table}
        FOR ALL USING (user_has_role('gerente'));
    `,
    
    OWNER_ONLY: (table) => `
        CREATE POLICY "owner_only_${table}" ON ${table}
        FOR ALL USING (user_has_role('proprietario'));
    `,
    
    USER_OWN_DATA: (table) => `
        CREATE POLICY "user_own_data_${table}" ON ${table}
        FOR ALL USING (usuario_id = auth.uid());
    `
};

// Data validation rules
export const VALIDATION_RULES = {
    USER_ROLES: ['proprietario', 'gerente', 'funcionario', 'veterinario'],
    ANIMAL_STATUS: ['ativo', 'doente', 'seco', 'prenhe', 'descartado'],
    SHIFTS: ['manha', 'tarde', 'noite'],
    PAYMENT_STATUS: ['pendente', 'pago', 'atrasado', 'cancelado'],
    PAYMENT_METHODS: ['pix', 'transferencia', 'dinheiro', 'cheque'],
    TREATMENT_TYPES: ['preventivo', 'curativo', 'vacina', 'exame']
};

// Default values
export const DEFAULTS = {
    USER_ACTIVE: true,
    ANIMAL_STATUS: 'ativo',
    PAYMENT_STATUS: 'pendente',
    SHIFT: 'manha'
};

// Error messages in Portuguese
export const ERROR_MESSAGES = {
    NOT_FOUND: 'Registro não encontrado',
    UNAUTHORIZED: 'Acesso não autorizado',
    VALIDATION_ERROR: 'Erro de validação dos dados',
    DUPLICATE_ENTRY: 'Registro duplicado',
    FOREIGN_KEY_ERROR: 'Referência inválida',
    REQUIRED_FIELD: 'Campo obrigatório não preenchido',
    INVALID_FORMAT: 'Formato inválido',
    FARM_REQUIRED: 'Fazenda é obrigatória',
    USER_INACTIVE: 'Usuário inativo',
    INSUFFICIENT_PERMISSIONS: 'Permissões insuficientes'
};
