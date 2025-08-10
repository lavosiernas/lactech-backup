// Supabase client wrapper with standardized error handling and queries
// NEW SUPABASE PROJECT: mauioyodoxmuzqweaasc.supabase.co

import { TABLES, COLUMNS, QUERY_PATTERNS, ERROR_MESSAGES } from './database-schema.js';

class SupabaseClient {
    constructor() {
        this.client = null;
        this.currentUser = null;
        this.currentFarmId = null;
    }

    // Initialize Supabase client
    async initialize(supabaseUrl, supabaseKey) {
        try {
            if (typeof window.supabase === 'undefined') {
                this.client = window.createClient(supabaseUrl, supabaseKey);
            } else {
                this.client = window.supabase;
            }
            
            // Get current user and farm
            await this.getCurrentUser();
            
            console.log('✅ Supabase client initialized successfully');
            return true;
        } catch (error) {
            console.error('❌ Failed to initialize Supabase client:', error);
            throw new Error('Falha ao conectar com o banco de dados');
        }
    }

    // Get current authenticated user
    async getCurrentUser() {
        try {
            const { data: { user }, error } = await this.client.auth.getUser();
            
            if (error) throw error;
            if (!user) throw new Error(ERROR_MESSAGES.UNAUTHORIZED);

            this.currentUser = user;

            // Get user farm_id
            const userData = await this.getUserData(user.id);
            this.currentFarmId = userData.fazenda_id;

            return user;
        } catch (error) {
            console.error('Error getting current user:', error);
            throw new Error(ERROR_MESSAGES.UNAUTHORIZED);
        }
    }

    // Get user data by ID
    async getUserData(userId) {
        try {
            const { data, error } = await this.client
                .from(TABLES.USUARIOS)
                .select('*')
                .eq(COLUMNS.ID, userId)
                .is(COLUMNS.DELETED_AT, null)
                .single();

            if (error) throw error;
            if (!data) throw new Error(ERROR_MESSAGES.NOT_FOUND);

            return data;
        } catch (error) {
            console.error('Error getting user data:', error);
            throw new Error('Dados do usuário não encontrados');
        }
    }

    // Generic query builder
    async query(queryPattern) {
        try {
            let query = this.client.from(queryPattern.table);

            // Build select
            if (queryPattern.select) {
                query = query.select(queryPattern.select);
            }

            // Build insert
            if (queryPattern.insert) {
                query = query.insert(queryPattern.insert);
            }

            // Build update
            if (queryPattern.update) {
                query = query.update(queryPattern.update);
            }

            // Build filters
            if (queryPattern.eq) {
                query = query.eq(queryPattern.eq[0], queryPattern.eq[1]);
            }

            if (queryPattern.neq) {
                query = query.neq(queryPattern.neq[0], queryPattern.neq[1]);
            }

            if (queryPattern.gte) {
                query = query.gte(queryPattern.gte[0], queryPattern.gte[1]);
            }

            if (queryPattern.lte) {
                query = query.lte(queryPattern.lte[0], queryPattern.lte[1]);
            }

            if (queryPattern.is) {
                query = query.is(queryPattern.is[0], queryPattern.is[1]);
            }

            if (queryPattern.in) {
                query = query.in(queryPattern.in[0], queryPattern.in[1]);
            }

            // Build order
            if (queryPattern.order) {
                query = query.order(queryPattern.order[0], queryPattern.order[1]);
            }

            // Build limit
            if (queryPattern.limit) {
                query = query.limit(queryPattern.limit);
            }

            // Execute query
            const result = queryPattern.single ? await query.single() : await query;

            if (result.error) {
                throw result.error;
            }

            return result.data;
        } catch (error) {
            console.error('Query error:', error);
            this.handleError(error);
        }
    }

    // Standardized CRUD operations
    async create(table, data) {
        try {
            // Add farm_id and timestamps
            const createData = {
                ...data,
                [COLUMNS.FARM_ID]: this.currentFarmId,
                [COLUMNS.CREATED_AT]: new Date().toISOString()
            };

            return await this.query(QUERY_PATTERNS.INSERT(table, createData));
        } catch (error) {
            console.error('Create error:', error);
            this.handleError(error);
        }
    }

    async getById(table, id) {
        try {
            return await this.query(QUERY_PATTERNS.SELECT_BY_ID(table, id));
        } catch (error) {
            console.error('Get by ID error:', error);
            this.handleError(error);
        }
    }

    async getAll(table, filters = {}) {
        try {
            const queryPattern = {
                table,
                select: '*',
                eq: [COLUMNS.FARM_ID, this.currentFarmId],
                is: [COLUMNS.DELETED_AT, null],
                order: [COLUMNS.CREATED_AT, { ascending: false }],
                ...filters
            };

            return await this.query(queryPattern);
        } catch (error) {
            console.error('Get all error:', error);
            this.handleError(error);
        }
    }

    async update(table, id, data) {
        try {
            // Add updated timestamp
            const updateData = {
                ...data,
                [COLUMNS.UPDATED_AT]: new Date().toISOString()
            };

            return await this.query(QUERY_PATTERNS.UPDATE(table, id, updateData));
        } catch (error) {
            console.error('Update error:', error);
            this.handleError(error);
        }
    }

    async softDelete(table, id) {
        try {
            return await this.query(QUERY_PATTERNS.SOFT_DELETE(table, id));
        } catch (error) {
            console.error('Soft delete error:', error);
            this.handleError(error);
        }
    }

    // Farm-specific queries
    async getUsersByFarm() {
        try {
            return await this.query(QUERY_PATTERNS.USERS_BY_FARM(this.currentFarmId));
        } catch (error) {
            console.error('Get users by farm error:', error);
            this.handleError(error);
        }
    }

    async getProductionByDateRange(startDate, endDate) {
        try {
            return await this.query(QUERY_PATTERNS.PRODUCTION_BY_DATE_RANGE(this.currentFarmId, startDate, endDate));
        } catch (error) {
            console.error('Get production by date range error:', error);
            this.handleError(error);
        }
    }

    async getActiveAnimals() {
        try {
            return await this.query(QUERY_PATTERNS.ANIMALS_ACTIVE(this.currentFarmId));
        } catch (error) {
            console.error('Get active animals error:', error);
            this.handleError(error);
        }
    }

    // Authentication methods
    async signIn(email, password) {
        try {
            const { data, error } = await this.client.auth.signInWithPassword({
                email,
                password
            });

            if (error) throw error;

            // Verify user exists and is active
            const userData = await this.getUserData(data.user.id);
            
            if (!userData.ativo) {
                await this.client.auth.signOut();
                throw new Error(ERROR_MESSAGES.USER_INACTIVE);
            }

            this.currentUser = data.user;
            this.currentFarmId = userData.fazenda_id;

            return data;
        } catch (error) {
            console.error('Sign in error:', error);
            this.handleError(error);
        }
    }

    async signOut() {
        try {
            const { error } = await this.client.auth.signOut();
            if (error) throw error;

            this.currentUser = null;
            this.currentFarmId = null;
        } catch (error) {
            console.error('Sign out error:', error);
            this.handleError(error);
        }
    }

    async signUp(email, password, userData) {
        try {
            const { data, error } = await this.client.auth.signUp({
                email,
                password
            });

            if (error) throw error;

            // Create user record
            await this.create(TABLES.USUARIOS, {
                ...userData,
                [COLUMNS.ID]: data.user.id,
                [COLUMNS.USER_EMAIL]: email
            });

            return data;
        } catch (error) {
            console.error('Sign up error:', error);
            this.handleError(error);
        }
    }

    // Error handling
    handleError(error) {
        console.error('Supabase error:', error);

        // Map Supabase errors to user-friendly messages
        let message = ERROR_MESSAGES.VALIDATION_ERROR;

        if (error.code === 'PGRST116') {
            message = ERROR_MESSAGES.NOT_FOUND;
        } else if (error.code === '23505') {
            message = ERROR_MESSAGES.DUPLICATE_ENTRY;
        } else if (error.code === '23503') {
            message = ERROR_MESSAGES.FOREIGN_KEY_ERROR;
        } else if (error.message.includes('JWT')) {
            message = ERROR_MESSAGES.UNAUTHORIZED;
        } else if (error.message.includes('RLS')) {
            message = ERROR_MESSAGES.INSUFFICIENT_PERMISSIONS;
        }

        // Show user notification
        if (typeof window.showNotification === 'function') {
            window.showNotification(message, 'error');
        }

        throw new Error(message);
    }

    // Utility methods
    isAuthenticated() {
        return !!this.currentUser;
    }

    getCurrentFarmId() {
        return this.currentFarmId;
    }

    getCurrentUserId() {
        return this.currentUser?.id;
    }
}

// Export singleton instance
export const supabaseClient = new SupabaseClient();

// Export for global access
window.supabaseClient = supabaseClient;
