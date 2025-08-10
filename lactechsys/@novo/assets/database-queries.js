// Standardized database queries for all LacTech operations

import { supabaseClient } from './supabase-client.js';
import { TABLES, COLUMNS, VALIDATION_RULES, DEFAULTS } from './database-schema.js';

// Farm Operations
export const farmQueries = {
    async create(farmData) {
        const data = {
            [COLUMNS.FARM_NAME]: farmData.nome,
            [COLUMNS.FARM_CNPJ]: farmData.cnpj,
            [COLUMNS.FARM_PHONE]: farmData.telefone,
            [COLUMNS.FARM_ADDRESS]: farmData.endereco,
            [COLUMNS.FARM_CITY]: farmData.cidade,
            [COLUMNS.FARM_STATE]: farmData.estado
        };
        
        return await supabaseClient.create(TABLES.FAZENDAS, data);
    },

    async getById(farmId) {
        return await supabaseClient.getById(TABLES.FAZENDAS, farmId);
    },

    async update(farmId, farmData) {
        const data = {
            [COLUMNS.FARM_NAME]: farmData.nome,
            [COLUMNS.FARM_PHONE]: farmData.telefone,
            [COLUMNS.FARM_ADDRESS]: farmData.endereco,
            [COLUMNS.FARM_CITY]: farmData.cidade,
            [COLUMNS.FARM_STATE]: farmData.estado
        };
        
        return await supabaseClient.update(TABLES.FAZENDAS, farmId, data);
    }
};

// User Operations
export const userQueries = {
    async create(userData) {
        // Validate role
        if (!VALIDATION_RULES.USER_ROLES.includes(userData.cargo)) {
            throw new Error('Cargo inválido');
        }

        const data = {
            [COLUMNS.USER_NAME]: userData.nome,
            [COLUMNS.USER_EMAIL]: userData.email,
            [COLUMNS.USER_ROLE]: userData.cargo,
            [COLUMNS.USER_PHONE]: userData.telefone,
            [COLUMNS.USER_ACTIVE]: DEFAULTS.USER_ACTIVE
        };
        
        return await supabaseClient.create(TABLES.USUARIOS, data);
    },

    async getAll() {
        return await supabaseClient.getUsersByFarm();
    },

    async getById(userId) {
        return await supabaseClient.getById(TABLES.USUARIOS, userId);
    },

    async update(userId, userData) {
        const data = {
            [COLUMNS.USER_NAME]: userData.nome,
            [COLUMNS.USER_PHONE]: userData.telefone,
            [COLUMNS.USER_ACTIVE]: userData.ativo
        };
        
        if (userData.cargo && VALIDATION_RULES.USER_ROLES.includes(userData.cargo)) {
            data[COLUMNS.USER_ROLE] = userData.cargo;
        }
        
        return await supabaseClient.update(TABLES.USUARIOS, userId, data);
    },

    async activate(userId) {
        return await supabaseClient.update(TABLES.USUARIOS, userId, {
            [COLUMNS.USER_ACTIVE]: true
        });
    },

    async deactivate(userId) {
        return await supabaseClient.update(TABLES.USUARIOS, userId, {
            [COLUMNS.USER_ACTIVE]: false
        });
    },

    async delete(userId) {
        return await supabaseClient.softDelete(TABLES.USUARIOS, userId);
    }
};

// Animal Operations
export const animalQueries = {
    async create(animalData) {
        // Validate status
        if (!VALIDATION_RULES.ANIMAL_STATUS.includes(animalData.status)) {
            throw new Error('Status do animal inválido');
        }

        const data = {
            [COLUMNS.ANIMAL_NAME]: animalData.nome,
            [COLUMNS.ANIMAL_BREED]: animalData.raca,
            [COLUMNS.ANIMAL_BIRTH_DATE]: animalData.dataNascimento,
            [COLUMNS.ANIMAL_TAG]: animalData.brinco,
            [COLUMNS.ANIMAL_WEIGHT]: animalData.peso,
            [COLUMNS.ANIMAL_STATUS]: animalData.status || DEFAULTS.ANIMAL_STATUS
        };
        
        return await supabaseClient.create(TABLES.ANIMAIS, data);
    },

    async getAll() {
        return await supabaseClient.getActiveAnimals();
    },

    async getById(animalId) {
        return await supabaseClient.getById(TABLES.ANIMAIS, animalId);
    },

    async update(animalId, animalData) {
        const data = {
            [COLUMNS.ANIMAL_NAME]: animalData.nome,
            [COLUMNS.ANIMAL_BREED]: animalData.raca,
            [COLUMNS.ANIMAL_WEIGHT]: animalData.peso,
            [COLUMNS.ANIMAL_STATUS]: animalData.status
        };
        
        return await supabaseClient.update(TABLES.ANIMAIS, animalId, data);
    },

    async updateStatus(animalId, status) {
        if (!VALIDATION_RULES.ANIMAL_STATUS.includes(status)) {
            throw new Error('Status do animal inválido');
        }
        
        return await supabaseClient.update(TABLES.ANIMAIS, animalId, {
            [COLUMNS.ANIMAL_STATUS]: status
        });
    },

    async delete(animalId) {
        return await supabaseClient.softDelete(TABLES.ANIMAIS, animalId);
    }
};

// Production Operations
export const productionQueries = {
    async create(productionData) {
        // Validate shift
        if (!VALIDATION_RULES.SHIFTS.includes(productionData.turno)) {
            throw new Error('Turno inválido');
        }

        const data = {
            [COLUMNS.PRODUCTION_DATE]: productionData.dataProducao,
            [COLUMNS.PRODUCTION_TIME]: productionData.horaProducao,
            [COLUMNS.VOLUME_LITERS]: parseFloat(productionData.volumeLitros),
            [COLUMNS.SHIFT]: productionData.turno,
            [COLUMNS.TEMPERATURE]: productionData.temperatura ? parseFloat(productionData.temperatura) : null,
            [COLUMNS.OBSERVATIONS]: productionData.observacoes,
            [COLUMNS.USER_ID]: supabaseClient.getCurrentUserId()
        };
        
        return await supabaseClient.create(TABLES.PRODUCAO_LEITE, data);
    },

    async getAll(limit = 50) {
        return await supabaseClient.getAll(TABLES.PRODUCAO_LEITE, {
            select: `
                *,
                ${TABLES.USUARIOS}(${COLUMNS.USER_NAME})
            `,
            limit
        });
    },

    async getByDateRange(startDate, endDate) {
        return await supabaseClient.getProductionByDateRange(startDate, endDate);
    },

    async getByUser(userId, limit = 20) {
        return await supabaseClient.getAll(TABLES.PRODUCAO_LEITE, {
            select: `
                *,
                ${TABLES.USUARIOS}(${COLUMNS.USER_NAME})
            `,
            eq: [COLUMNS.USER_ID, userId],
            limit
        });
    },

    async getToday() {
        const today = new Date().toISOString().split('T')[0];
        return await this.getByDateRange(today, today);
    },

    async getStats(days = 7) {
        const endDate = new Date().toISOString().split('T')[0];
        const startDate = new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
        
        const data = await this.getByDateRange(startDate, endDate);
        
        const totalVolume = data.reduce((sum, record) => sum + parseFloat(record[COLUMNS.VOLUME_LITERS] || 0), 0);
        const avgVolume = data.length > 0 ? totalVolume / data.length : 0;
        const recordCount = data.length;
        
        return {
            totalVolume,
            avgVolume,
            recordCount,
            periodDays: days
        };
    },

    async update(productionId, productionData) {
        const data = {
            [COLUMNS.PRODUCTION_DATE]: productionData.dataProducao,
            [COLUMNS.PRODUCTION_TIME]: productionData.horaProducao,
            [COLUMNS.VOLUME_LITERS]: parseFloat(productionData.volumeLitros),
            [COLUMNS.SHIFT]: productionData.turno,
            [COLUMNS.TEMPERATURE]: productionData.temperatura ? parseFloat(productionData.temperatura) : null,
            [COLUMNS.OBSERVATIONS]: productionData.observacoes
        };
        
        return await supabaseClient.update(TABLES.PRODUCAO_LEITE, productionId, data);
    },

    async delete(productionId) {
        return await supabaseClient.softDelete(TABLES.PRODUCAO_LEITE, productionId);
    }
};

// Quality Test Operations
export const qualityQueries = {
    async create(qualityData) {
        const data = {
            [COLUMNS.TEST_DATE]: qualityData.dataTeste,
            [COLUMNS.FAT_PERCENTAGE]: parseFloat(qualityData.percentualGordura),
            [COLUMNS.PROTEIN_PERCENTAGE]: parseFloat(qualityData.percentualProteina),
            [COLUMNS.SOMATIC_CELL_COUNT]: parseInt(qualityData.contagemCelulasSomaticas),
            [COLUMNS.TOTAL_BACTERIAL_COUNT]: parseInt(qualityData.contagemBacteriasTotais),
            [COLUMNS.USER_ID]: supabaseClient.getCurrentUserId()
        };
        
        return await supabaseClient.create(TABLES.TESTES_QUALIDADE, data);
    },

    async getAll(limit = 30) {
        return await supabaseClient.getAll(TABLES.TESTES_QUALIDADE, {
            select: `
                *,
                ${TABLES.USUARIOS}(${COLUMNS.USER_NAME})
            `,
            limit
        });
    },

    async getByDateRange(startDate, endDate) {
        return await supabaseClient.getAll(TABLES.TESTES_QUALIDADE, {
            gte: [COLUMNS.TEST_DATE, startDate],
            lte: [COLUMNS.TEST_DATE, endDate],
            order: [COLUMNS.TEST_DATE, { ascending: false }]
        });
    },

    async getLatest() {
        return await supabaseClient.getAll(TABLES.TESTES_QUALIDADE, {
            limit: 1,
            order: [COLUMNS.TEST_DATE, { ascending: false }]
        });
    },

    async update(qualityId, qualityData) {
        const data = {
            [COLUMNS.TEST_DATE]: qualityData.dataTeste,
            [COLUMNS.FAT_PERCENTAGE]: parseFloat(qualityData.percentualGordura),
            [COLUMNS.PROTEIN_PERCENTAGE]: parseFloat(qualityData.percentualProteina),
            [COLUMNS.SOMATIC_CELL_COUNT]: parseInt(qualityData.contagemCelulasSomaticas),
            [COLUMNS.TOTAL_BACTERIAL_COUNT]: parseInt(qualityData.contagemBacteriasTotais)
        };
        
        return await supabaseClient.update(TABLES.TESTES_QUALIDADE, qualityId, data);
    },

    async delete(qualityId) {
        return await supabaseClient.softDelete(TABLES.TESTES_QUALIDADE, qualityId);
    }
};

// Payment Operations
export const paymentQueries = {
    async create(paymentData) {
        // Validate status and method
        if (!VALIDATION_RULES.PAYMENT_STATUS.includes(paymentData.statusPagamento)) {
            throw new Error('Status de pagamento inválido');
        }
        
        if (!VALIDATION_RULES.PAYMENT_METHODS.includes(paymentData.metodoPagamento)) {
            throw new Error('Método de pagamento inválido');
        }

        const data = {
            [COLUMNS.PAYMENT_DATE]: paymentData.dataPagamento,
            [COLUMNS.VOLUME_LITERS]: parseFloat(paymentData.volumeLitros),
            [COLUMNS.GROSS_AMOUNT]: parseFloat(paymentData.valorBruto),
            [COLUMNS.NET_AMOUNT]: parseFloat(paymentData.valorLiquido),
            [COLUMNS.PAYMENT_STATUS]: paymentData.statusPagamento || DEFAULTS.PAYMENT_STATUS,
            [COLUMNS.PAYMENT_METHOD]: paymentData.metodoPagamento
        };
        
        return await supabaseClient.create(TABLES.PAGAMENTOS, data);
    },

    async getAll(limit = 50) {
        return await supabaseClient.getAll(TABLES.PAGAMENTOS, {
            order: [COLUMNS.PAYMENT_DATE, { ascending: false }],
            limit
        });
    },

    async getByDateRange(startDate, endDate) {
        return await supabaseClient.getAll(TABLES.PAGAMENTOS, {
            gte: [COLUMNS.PAYMENT_DATE, startDate],
            lte: [COLUMNS.PAYMENT_DATE, endDate],
            order: [COLUMNS.PAYMENT_DATE, { ascending: false }]
        });
    },

    async getByStatus(status) {
        if (!VALIDATION_RULES.PAYMENT_STATUS.includes(status)) {
            throw new Error('Status de pagamento inválido');
        }
        
        return await supabaseClient.getAll(TABLES.PAGAMENTOS, {
            eq: [COLUMNS.PAYMENT_STATUS, status],
            order: [COLUMNS.PAYMENT_DATE, { ascending: false }]
        });
    },

    async updateStatus(paymentId, status) {
        if (!VALIDATION_RULES.PAYMENT_STATUS.includes(status)) {
            throw new Error('Status de pagamento inválido');
        }
        
        return await supabaseClient.update(TABLES.PAGAMENTOS, paymentId, {
            [COLUMNS.PAYMENT_STATUS]: status
        });
    },

    async update(paymentId, paymentData) {
        const data = {
            [COLUMNS.PAYMENT_DATE]: paymentData.dataPagamento,
            [COLUMNS.VOLUME_LITERS]: parseFloat(paymentData.volumeLitros),
            [COLUMNS.GROSS_AMOUNT]: parseFloat(paymentData.valorBruto),
            [COLUMNS.NET_AMOUNT]: parseFloat(paymentData.valorLiquido),
            [COLUMNS.PAYMENT_STATUS]: paymentData.statusPagamento,
            [COLUMNS.PAYMENT_METHOD]: paymentData.metodoPagamento
        };
        
        return await supabaseClient.update(TABLES.PAGAMENTOS, paymentId, data);
    },

    async delete(paymentId) {
        return await supabaseClient.softDelete(TABLES.PAGAMENTOS, paymentId);
    }
};

// Treatment Operations
export const treatmentQueries = {
    async create(treatmentData) {
        // Validate treatment type
        if (!VALIDATION_RULES.TREATMENT_TYPES.includes(treatmentData.tipoTratamento)) {
            throw new Error('Tipo de tratamento inválido');
        }

        const data = {
            [COLUMNS.ANIMAL_ID]: treatmentData.animalId,
            [COLUMNS.TREATMENT_DATE]: treatmentData.dataTratamento,
            [COLUMNS.TREATMENT_TYPE]: treatmentData.tipoTratamento,
            [COLUMNS.MEDICATION]: treatmentData.medicamento,
            [COLUMNS.DOSAGE]: treatmentData.dosagem,
            [COLUMNS.VETERINARIAN]: treatmentData.veterinario,
            [COLUMNS.HEALTH_STATUS]: treatmentData.statusSaude,
            [COLUMNS.OBSERVATIONS]: treatmentData.observacoes,
            [COLUMNS.USER_ID]: supabaseClient.getCurrentUserId()
        };
        
        return await supabaseClient.create(TABLES.TRATAMENTOS_VETERINARIOS, data);
    },

    async getAll(limit = 50) {
        return await supabaseClient.getAll(TABLES.TRATAMENTOS_VETERINARIOS, {
            select: `
                *,
                ${TABLES.ANIMAIS}(${COLUMNS.ANIMAL_NAME}, ${COLUMNS.ANIMAL_TAG}),
                ${TABLES.USUARIOS}(${COLUMNS.USER_NAME})
            `,
            limit
        });
    },

    async getByAnimal(animalId) {
        return await supabaseClient.getAll(TABLES.TRATAMENTOS_VETERINARIOS, {
            select: `
                *,
                ${TABLES.USUARIOS}(${COLUMNS.USER_NAME})
            `,
            eq: [COLUMNS.ANIMAL_ID, animalId],
            order: [COLUMNS.TREATMENT_DATE, { ascending: false }]
        });
    },

    async getByDateRange(startDate, endDate) {
        return await supabaseClient.getAll(TABLES.TRATAMENTOS_VETERINARIOS, {
            select: `
                *,
                ${TABLES.ANIMAIS}(${COLUMNS.ANIMAL_NAME}, ${COLUMNS.ANIMAL_TAG}),
                ${TABLES.USUARIOS}(${COLUMNS.USER_NAME})
            `,
            gte: [COLUMNS.TREATMENT_DATE, startDate],
            lte: [COLUMNS.TREATMENT_DATE, endDate],
            order: [COLUMNS.TREATMENT_DATE, { ascending: false }]
        });
    },

    async update(treatmentId, treatmentData) {
        const data = {
            [COLUMNS.TREATMENT_DATE]: treatmentData.dataTratamento,
            [COLUMNS.TREATMENT_TYPE]: treatmentData.tipoTratamento,
            [COLUMNS.MEDICATION]: treatmentData.medicamento,
            [COLUMNS.DOSAGE]: treatmentData.dosagem,
            [COLUMNS.VETERINARIAN]: treatmentData.veterinario,
            [COLUMNS.HEALTH_STATUS]: treatmentData.statusSaude,
            [COLUMNS.OBSERVATIONS]: treatmentData.observacoes
        };
        
        return await supabaseClient.update(TABLES.TRATAMENTOS_VETERINARIOS, treatmentId, data);
    },

    async delete(treatmentId) {
        return await supabaseClient.softDelete(TABLES.TRATAMENTOS_VETERINARIOS, treatmentId);
    }
};

// Export all queries
export const queries = {
    farm: farmQueries,
    user: userQueries,
    animal: animalQueries,
    production: productionQueries,
    quality: qualityQueries,
    payment: paymentQueries,
    treatment: treatmentQueries
};
