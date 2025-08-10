// gerente.js - Manager dashboard functionality

import { supabaseClient } from './supabase-client.js';
import { queries } from './database-queries.js';
import { TABLES, COLUMNS, VALIDATION_RULES } from './database-schema.js';

// State management
let currentUser = null;
let currentFarmId = null;
let users = [];
let animals = [];
let productions = [];
let selectedAnimalIds = [];
let selectedUserIds = [];
let selectedProductionIds = [];

// Supabase configuration
const SUPABASE_CONFIG = {
    url: 'https://mauioyodoxmuzqweaasc.supabase.co',
    key: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1hdWlveW9kb3htdXpxd2VhYXNjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ3NzYyNzksImV4cCI6MjA3MDM1MjI3OX0.m2nZ_5Vbi9aBz1vZ_oA-JHsd_yqD9brJXjnr39k7Ajc'
};

// Initialize page
document.addEventListener('DOMContentLoaded', async function() {
    console.log('Gerente page loaded');
    
    try {
        // Initialize Supabase client
        await supabaseClient.initialize(SUPABASE_CONFIG.url, SUPABASE_CONFIG.key);
        
        // Initialize theme
        initializeTheme();
        
        // Hide modals on load
        hideModalsOnLoad();
        
        // Setup event listeners
        setupEventListeners();
        
        // Check authentication and load data
        await checkAuth();
        
    } catch (error) {
        console.error('Error initializing manager page:', error);
        showNotification('Erro ao carregar página. Redirecionando...', 'error');
        setTimeout(() => {
            window.location.href = './login.html';
        }, 2000);
    }
});

function initializeTheme() {
    const savedTheme = localStorage.getItem('theme');
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    
    if (savedTheme === 'dark' || (!savedTheme && prefersDark)) {
        document.documentElement.classList.add('dark');
        const toggle = document.getElementById('themeToggle');
        if (toggle) toggle.checked = true;
    }
}

function toggleTheme() {
    const html = document.documentElement;
    const isDark = html.classList.contains('dark');
    
    if (isDark) {
        html.classList.remove('dark');
        localStorage.setItem('theme', 'light');
    } else {
        html.classList.add('dark');
        localStorage.setItem('theme', 'dark');
    }
}

function hideModalsOnLoad() {
    // Hide overlay modals
    const overlayModals = ['deleteUserModal', 'addUserModal', 'editUserModal', 'photoChoiceModal'];
    overlayModals.forEach(modalId => {
        const modal = document.getElementById(modalId);
        if (modal) {
            modal.classList.add('hidden');
            modal.classList.remove('flex');
        }
    });
    
    // Hide fullscreen modals
    const fullscreenModals = ['profileModal'];
    fullscreenModals.forEach(modalId => {
        const modal = document.getElementById(modalId);
        if (modal) {
            modal.classList.remove('show');
        }
    });
}

function setupEventListeners() {
    // Theme toggle
    const themeToggle = document.getElementById('themeToggle');
    if (themeToggle) {
        themeToggle.addEventListener('change', toggleTheme);
    }
    
    // Modal close buttons and outside clicks
    setupModalEventListeners();
}

function setupModalEventListeners() {
    // Close modals when clicking outside
    document.addEventListener('click', function(e) {
        if (e.target.classList.contains('modal-overlay')) {
            closeAllModals();
        }
    });
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

function openAddUserModal() {
    const modal = document.getElementById('addUserModal');
    if (modal) {
        modal.classList.remove('hidden');
        modal.classList.add('flex');
    }
}

function closeAddUserModal() {
    const modal = document.getElementById('addUserModal');
    if (modal) {
        modal.classList.add('hidden');
        modal.classList.remove('flex');
    }
}

function openEditUserModal() {
    const modal = document.getElementById('editUserModal');
    if (modal) {
        modal.classList.remove('hidden');
        modal.classList.add('flex');
    }
}

function closeEditUserModal() {
    const modal = document.getElementById('editUserModal');
    if (modal) {
        modal.classList.add('hidden');
        modal.classList.remove('flex');
    }
}

function openDeleteUserModal() {
    const modal = document.getElementById('deleteUserModal');
    if (modal) {
        modal.classList.remove('hidden');
        modal.classList.add('flex');
    }
}

function closeDeleteUserModal() {
    const modal = document.getElementById('deleteUserModal');
    if (modal) {
        modal.classList.add('hidden');
        modal.classList.remove('flex');
    }
}

function openPhotoChoiceModal() {
    const modal = document.getElementById('photoChoiceModal');
    if (modal) {
        modal.classList.remove('hidden');
        modal.classList.add('flex');
    }
}

function closePhotoChoiceModal() {
    const modal = document.getElementById('photoChoiceModal');
    if (modal) {
        modal.classList.add('hidden');
        modal.classList.remove('flex');
    }
}

function closeAllModals() {
    closeProfileModal();
    closeAddUserModal();
    closeEditUserModal();
    closeDeleteUserModal();
    closePhotoChoiceModal();
}

// Authentication and user management
async function checkAuth() {
    try {
        currentUser = await supabaseClient.getCurrentUser();
        currentFarmId = supabaseClient.getCurrentFarmId();
        
        // Verify manager role
        const userData = await supabaseClient.getUserData(currentUser.id);
        if (userData.cargo !== 'gerente') {
            throw new Error('Acesso restrito a gerentes');
        }
        
        // Load initial data
        await Promise.all([
            loadUsers(),
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
async function loadUsers() {
    try {
        users = await queries.user.getAll();
        updateUsersTable();
        updateUserStats();
    } catch (error) {
        console.error('Error loading users:', error);
        showNotification('Erro ao carregar usuários', 'error');
        users = [];
    }
}

async function loadAnimals() {
    try {
        animals = await queries.animal.getAll();
        updateAnimalsTable();
        updateAnimalStats();
    } catch (error) {
        console.error('Error loading animals:', error);
        showNotification('Erro ao carregar animais', 'error');
        animals = [];
    }
}

async function loadProductions() {
    try {
        productions = await queries.production.getAll();
        updateProductionsTable();
        updateProductionStats();
    } catch (error) {
        console.error('Error loading productions:', error);
        showNotification('Erro ao carregar produção', 'error');
        productions = [];
    }
}

async function loadDashboardStats() {
    try {
        const stats = await queries.production.getStats(7);
        updateDashboardStats(stats);
    } catch (error) {
        console.error('Error loading dashboard stats:', error);
    }
}

// User management functions
async function addUser() {
    try {
        const form = document.getElementById('addUserForm');
        const formData = new FormData(form);
        
        const userData = {
            nome: formData.get('userName'),
            email: formData.get('userEmail'),
            cargo: formData.get('userRole'),
            telefone: formData.get('userPhone') || null
        };
        
        // Validate required fields
        if (!userData.nome || !userData.email || !userData.cargo) {
            throw new Error('Todos os campos obrigatórios devem ser preenchidos');
        }
        
        // Validate email format
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(userData.email)) {
            throw new Error('Email inválido');
        }
        
        await queries.user.create(userData);
        
        showNotification('Usuário adicionado com sucesso!', 'success');
        closeAddUserModal();
        form.reset();
        await loadUsers();
        
    } catch (error) {
        console.error('Error adding user:', error);
        showNotification('Erro ao adicionar usuário: ' + error.message, 'error');
    }
}

async function editUser(userId) {
    try {
        // Get user data
        const user = await queries.user.getById(userId);
        
        // Populate edit form
        document.getElementById('editUserId').value = user.id;
        document.getElementById('editUserName').value = user.nome;
        document.getElementById('editUserEmail').value = user.email;
        document.getElementById('editUserRole').value = user.cargo;
        document.getElementById('editUserActive').checked = user.ativo;
        
        openEditUserModal();
        
    } catch (error) {
        console.error('Error loading user for edit:', error);
        showNotification('Erro ao carregar dados do usuário', 'error');
    }
}

async function saveUserEdit() {
    try {
        const form = document.getElementById('editUserForm');
        const formData = new FormData(form);
        
        const userId = formData.get('editUserId');
        const userData = {
            nome: formData.get('editUserName'),
            cargo: formData.get('editUserRole'),
            ativo: formData.get('editUserActive') === 'on'
        };
        
        await queries.user.update(userId, userData);
        
        showNotification('Usuário atualizado com sucesso!', 'success');
        closeEditUserModal();
        await loadUsers();
        
    } catch (error) {
        console.error('Error updating user:', error);
        showNotification('Erro ao atualizar usuário: ' + error.message, 'error');
    }
}

async function deleteUser(userId) {
    try {
        if (!confirm('Tem certeza que deseja excluir este usuário?')) {
            return;
        }
        
        await queries.user.delete(userId);
        
        showNotification('Usuário excluído com sucesso!', 'success');
        closeDeleteUserModal();
        await loadUsers();
        
    } catch (error) {
        console.error('Error deleting user:', error);
        showNotification('Erro ao excluir usuário: ' + error.message, 'error');
    }
}

// Animal management functions
async function addAnimal() {
    try {
        const form = document.getElementById('addAnimalForm');
        if (!form) return;
        
        const formData = new FormData(form);
        
        const animalData = {
            nome: formData.get('animalName'),
            raca: formData.get('animalBreed'),
            dataNascimento: formData.get('animalBirthDate'),
            brinco: formData.get('animalTag'),
            peso: formData.get('animalWeight') ? parseFloat(formData.get('animalWeight')) : null,
            status: formData.get('animalStatus') || 'ativo'
        };
        
        // Validate required fields
        if (!animalData.nome || !animalData.raca || !animalData.brinco) {
            throw new Error('Nome, raça e brinco são obrigatórios');
        }
        
        await queries.animal.create(animalData);
        
        showNotification('Animal adicionado com sucesso!', 'success');
        form.reset();
        await loadAnimals();
        
    } catch (error) {
        console.error('Error adding animal:', error);
        showNotification('Erro ao adicionar animal: ' + error.message, 'error');
    }
}

// Production management functions
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

// Photo upload function
async function uploadPhoto() {
    try {
        // This will be implemented when file upload is needed
        showNotification('Funcionalidade de upload em desenvolvimento', 'info');
    } catch (error) {
        console.error('Error uploading photo:', error);
        showNotification('Erro ao fazer upload da foto', 'error');
    }
}

// Profile update function
async function updateProfile() {
    try {
        // This will be implemented when profile editing is needed
        showNotification('Funcionalidade de perfil em desenvolvimento', 'info');
    } catch (error) {
        console.error('Error updating profile:', error);
        showNotification('Erro ao atualizar perfil', 'error');
    }
}

// UI update functions (placeholders for now)
function updateUserInterface(userData) {
    // Update header with user name
    const userNameElements = document.querySelectorAll('#employeeName, #profileName');
    userNameElements.forEach(el => {
        if (el) el.textContent = userData.nome;
    });
    
    // Update role display
    const roleElements = document.querySelectorAll('#profileRole');
    roleElements.forEach(el => {
        if (el) el.textContent = 'Gerente';
    });
}

function updateUsersTable() {
    // Update users table UI
    console.log('Updating users table with', users.length, 'users');
    const totalUsersEl = document.getElementById('total-users');
    if (totalUsersEl) totalUsersEl.textContent = users.length;
}

function updateAnimalsTable() {
    // Update animals table UI
    console.log('Updating animals table with', animals.length, 'animals');
    const totalAnimalsEl = document.getElementById('total-animals');
    if (totalAnimalsEl) totalAnimalsEl.textContent = animals.length;
}

function updateProductionsTable() {
    // Update productions table UI
    console.log('Updating productions table with', productions.length, 'records');
}

function updateUserStats() {
    // Update user statistics
    console.log('Updating user stats');
}

function updateAnimalStats() {
    // Update animal statistics
    console.log('Updating animal stats');
}

function updateProductionStats() {
    // Update production statistics
    console.log('Updating production stats');
}

function updateDashboardStats(stats) {
    // Update dashboard statistics
    console.log('Updating dashboard stats:', stats);
    
    const todayVolumeEl = document.getElementById('production-today');
    const weeklyAvgEl = document.getElementById('weekly-average');
    
    if (todayVolumeEl) todayVolumeEl.textContent = `${stats.totalVolume.toFixed(1)}L`;
    if (weeklyAvgEl) weeklyAvgEl.textContent = `${stats.avgVolume.toFixed(1)}L`;
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
window.openAddUserModal = openAddUserModal;
window.closeAddUserModal = closeAddUserModal;
window.openEditUserModal = openEditUserModal;
window.closeEditUserModal = closeEditUserModal;
window.openDeleteUserModal = openDeleteUserModal;
window.closeDeleteUserModal = closeDeleteUserModal;
window.openPhotoChoiceModal = openPhotoChoiceModal;
window.closePhotoChoiceModal = closePhotoChoiceModal;
window.toggleTheme = toggleTheme;
window.logout = logout;
window.addUser = addUser;
window.editUser = editUser;
window.saveUserEdit = saveUserEdit;
window.deleteUser = deleteUser;
window.addAnimal = addAnimal;
window.addProduction = addProduction;
window.uploadPhoto = uploadPhoto;
window.updateProfile = updateProfile;
window.showNotification = showNotification;
