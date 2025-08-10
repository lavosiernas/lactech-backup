// funcionario.js - Employee dashboard functionality

import { supabaseClient } from './supabase-client.js';
import { queries } from './database-queries.js';
import { TABLES, COLUMNS, VALIDATION_RULES } from './database-schema.js';

// State management
let currentUser = null;
let currentFarmId = null;
let animals = [];
let productions = [];

// Supabase configuration
const SUPABASE_CONFIG = {
    url: 'https://mauioyodoxmuzqweaasc.supabase.co',
    key: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1hdWlveW9kb3htdXpxd2VhYXNjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ3NzYyNzksImV4cCI6MjA3MDM1MjI3OX0.m2nZ_5Vbi9aBz1vZ_oA-JHsd_yqD9brJXjnr39k7Ajc'
};

// Initialize page
document.addEventListener('DOMContentLoaded', async function() {
    console.log('Funcionario page loaded');
    
    try {
        // Initialize Supabase client
        await supabaseClient.initialize(SUPABASE_CONFIG.url, SUPABASE_CONFIG.key);
        
        // Setup event listeners
        setupEventListeners();
        
        // Check authentication and load data
        await checkAuth();
        
    } catch (error) {
        console.error('Error initializing employee page:', error);
        showNotification('Erro ao carregar página. Redirecionando...', 'error');
        setTimeout(() => {
            window.location.href = './login.html';
        }, 2000);
    }
});



function setupEventListeners() {
    // Event listeners setup will be added here as needed
}

// Modal functions
function openProfileModal() {
    const modal = document.getElementById('profileModal');
    if (modal) {
        modal.classList.add('show');
    }
}

function closeProfileModal() {
    const modal = document.getElementById('profileModal');
    if (modal) {
        modal.classList.remove('show');
    }
}

// Authentication and data management
async function checkAuth() {
    try {
        currentUser = await supabaseClient.getCurrentUser();
        currentFarmId = supabaseClient.getCurrentFarmId();
        
        // Verify employee role
        const userData = await supabaseClient.getUserData(currentUser.id);
        if (userData.cargo !== 'funcionario') {
            throw new Error('Acesso restrito a funcionários');
        }
        
        // Load initial data
        await Promise.all([
            loadAnimals(),
            loadProductions(),
            loadDashboardStats()
        ]);
        
        // Update UI with user data
        updateUserInterface(userData);
        
    } catch (error) {
        console.error('Authentication error:', error);
        showNotification('Erro de autenticação. Redirecionando...', 'error');
        setTimeout(() => {
            window.location.href = './login.html';
        }, 2000);
    }
}

async function logout() {
    try {
        await supabaseClient.signOut();
        window.location.href = './login.html';
    } catch (error) {
        console.error('Logout error:', error);
        // Force redirect even if logout fails
        window.location.href = './login.html';
    }
}

// Data loading functions
async function loadAnimals() {
    try {
        animals = await queries.animal.getAll();
        updateAnimalsSelect();
    } catch (error) {
        console.error('Error loading animals:', error);
        animals = [];
    }
}

async function loadProductions() {
    try {
        productions = await queries.production.getByUser(currentUser.id, 20);
        updateProductionsHistory();
    } catch (error) {
        console.error('Error loading productions:', error);
        productions = [];
    }
}

async function loadDashboardStats() {
    try {
        const todayStats = await queries.production.getToday();
        const weekStats = await queries.production.getStats(7);
        updateDashboardStats(todayStats, weekStats);
    } catch (error) {
        console.error('Error loading dashboard stats:', error);
    }
}

// Production management
async function addProduction() {
    try {
        const form = document.getElementById('addProductionForm');
        if (!form) return;
        
        const formData = new FormData(form);
        
        const productionData = {
            dataProducao: formData.get('productionDate'),
            horaProducao: formData.get('productionTime'),
            volumeLitros: formData.get('volumeLiters'),
            turno: formData.get('shift'),
            temperatura: formData.get('temperature'),
            observacoes: formData.get('observations')
        };
        
        // Validate required fields
        if (!productionData.dataProducao || !productionData.volumeLitros || !productionData.turno) {
            throw new Error('Data, volume e turno são obrigatórios');
        }
        
        await queries.production.create(productionData);
        
        showNotification('Produção registrada com sucesso!', 'success');
        form.reset();
        await loadProductions();
        await loadDashboardStats();
        
    } catch (error) {
        console.error('Error adding production:', error);
        showNotification('Erro ao registrar produção: ' + error.message, 'error');
    }
}

async function updateProfile() {
    try {
        // This will be implemented when profile editing is needed
        showNotification('Funcionalidade de perfil em desenvolvimento', 'info');
    } catch (error) {
        console.error('Error updating profile:', error);
        showNotification('Erro ao atualizar perfil', 'error');
    }
}

// UI update functions
function updateUserInterface(userData) {
    // Update header with user name
    const userNameElements = document.querySelectorAll('#employeeName, #employeeWelcome');
    userNameElements.forEach(el => {
        if (el) el.textContent = userData.nome;
    });
}

function updateAnimalsSelect() {
    // Update animal select options
    console.log('Updating animals select with', animals.length, 'animals');
}

function updateProductionsHistory() {
    // Update production history table
    console.log('Updating production history with', productions.length, 'records');
}

function updateDashboardStats(todayStats, weekStats) {
    // Update dashboard statistics
    console.log('Updating dashboard stats');
    
    const todayVolumeEl = document.getElementById('todayVolume');
    const weekAverageEl = document.getElementById('weekAverage');
    const todayRecordsEl = document.getElementById('todayRecords');
    
    if (todayVolumeEl) {
        const todayTotal = todayStats.reduce((sum, record) => sum + parseFloat(record.volume_litros || 0), 0);
        todayVolumeEl.textContent = `${todayTotal.toFixed(1)} L`;
    }
    
    if (weekAverageEl) weekAverageEl.textContent = `${weekStats.avgVolume.toFixed(1)} L`;
    if (todayRecordsEl) todayRecordsEl.textContent = todayStats.length;
}

function showNotification(message, type = 'info') {
    // Create notification element
    const notification = document.createElement('div');
    notification.className = `fixed top-4 right-4 z-50 p-4 rounded-md shadow-lg max-w-sm notification-${type}`;
    
    // Set classes based on type
    const typeClasses = {
        success: 'bg-green-100 border-green-500 text-green-700',
        error: 'bg-red-100 border-red-500 text-red-700',
        warning: 'bg-yellow-100 border-yellow-500 text-yellow-700',
        info: 'bg-blue-100 border-blue-500 text-blue-700'
    };
    
    notification.className += ' ' + (typeClasses[type] || typeClasses.info);
    notification.textContent = message;
    
    document.body.appendChild(notification);
    
    // Remove after 5 seconds
    setTimeout(() => {
        if (notification.parentNode) {
            notification.parentNode.removeChild(notification);
        }
    }, 5000);
}

// Export functions for global access
window.openProfileModal = openProfileModal;
window.closeProfileModal = closeProfileModal;
window.logout = logout;
window.addProduction = addProduction;
window.updateProfile = updateProfile;
window.showNotification = showNotification;
