// login.js - Login page functionality

import { supabaseClient } from './supabase-client.js';
import { VALIDATION_RULES } from './database-schema.js';

// Supabase configuration
const SUPABASE_CONFIG = {
    url: 'https://mauioyodoxmuzqweaasc.supabase.co',
    key: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1hdWlveW9kb3htdXpxd2VhYXNjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ3NzYyNzksImV4cCI6MjA3MDM1MjI3OX0.m2nZ_5Vbi9aBz1vZ_oA-JHsd_yqD9brJXjnr39k7Ajc'
};

// Initialize page
document.addEventListener('DOMContentLoaded', async function() {
    console.log('Login page loaded');
    
    try {
        // Initialize Supabase client
        await supabaseClient.initialize(SUPABASE_CONFIG.url, SUPABASE_CONFIG.key);
        
        // Setup event listeners
        setupEventListeners();
        
        // Check for existing session
        await checkExistingSession();
        
    } catch (error) {
        console.error('Error initializing login page:', error);
        showNotification('Erro ao carregar página de login', 'error');
    }
});

function setupEventListeners() {
    // Login form
    const loginForm = document.getElementById('loginForm');
    if (loginForm) {
        loginForm.addEventListener('submit', handleLogin);
    }
    
    // Show/hide password
    const showPasswordBtn = document.getElementById('showPassword');
    if (showPasswordBtn) {
        showPasswordBtn.addEventListener('click', togglePasswordVisibility);
    }
    
    // Forgot password link
    const forgotPasswordLink = document.getElementById('forgotPassword');
    if (forgotPasswordLink) {
        forgotPasswordLink.addEventListener('click', handleForgotPassword);
    }
}

async function handleLogin(e) {
    e.preventDefault();
    
    // Determine if it's desktop or mobile
    const form = e.target;
    const isDesktop = form.id === 'loginFormDesktop';
    
    const email = document.getElementById(isDesktop ? 'emailDesktop' : 'email').value;
    const password = document.getElementById(isDesktop ? 'passwordDesktop' : 'password').value;
    
    if (!email || !password) {
        showNotification('Por favor, preencha todos os campos', 'error');
        return;
    }
    
    // Show loading state
    const submitBtn = document.querySelector('button[type="submit"]');
    const originalText = submitBtn.textContent;
    submitBtn.textContent = 'Entrando...';
    submitBtn.disabled = true;
    
    try {
        // Authenticate user
        const { data, error } = await supabaseClient.signIn(email, password);
        
        if (error) throw error;
        
        const userData = await supabaseClient.getUserData(data.user.id);
        
        // Check if user is active
        if (!userData.ativo) {
            await supabaseClient.signOut();
            throw new Error('Seu acesso foi bloqueado pela fazenda. Contate o administrador.');
        }
        
        // Redirect based on role
        redirectByRole(userData.cargo);
        
    } catch (error) {
        console.error('Erro no login:', error);
        
        // Handle specific error messages
        let errorMessage = 'Erro no login';
        if (error.message.includes('Invalid login credentials')) {
            errorMessage = 'Email ou senha incorretos';
        } else if (error.message.includes('bloqueado')) {
            errorMessage = error.message;
        } else {
            errorMessage = 'Erro no servidor. Tente novamente.';
        }
        
        showNotification(errorMessage, 'error');
    } finally {
        submitBtn.textContent = originalText;
        submitBtn.disabled = false;
    }
}

function togglePasswordVisibility() {
    const passwordInput = document.getElementById('password');
    const eyeIcon = document.querySelector('#showPassword svg');
    
    if (passwordInput.type === 'password') {
        passwordInput.type = 'text';
        // Update eye icon to show "hide" state
    } else {
        passwordInput.type = 'password';
        // Update eye icon to show "show" state
    }
}

function handleForgotPassword(e) {
    e.preventDefault();
    
    const email = document.getElementById('email').value;
    
    if (!email) {
        showNotification('Por favor, digite seu email primeiro', 'warning');
        document.getElementById('email').focus();
        return;
    }
    
    // Forgot password logic will be implemented when Supabase is reconnected
    showNotification('Função de recuperação de senha não implementada ainda', 'info');
}

function showNotification(message, type = 'info') {
    // Create notification element
    const notification = document.createElement('div');
    notification.className = `fixed top-4 right-4 z-50 p-4 rounded-md shadow-lg max-w-sm ${getNotificationClasses(type)}`;
    notification.textContent = message;
    
    document.body.appendChild(notification);
    
    // Remove after 5 seconds
    setTimeout(() => {
        if (notification.parentNode) {
            notification.parentNode.removeChild(notification);
        }
    }, 5000);
}

function getNotificationClasses(type) {
    switch (type) {
        case 'success':
            return 'bg-green-100 border-green-500 text-green-700';
        case 'error':
            return 'bg-red-100 border-red-500 text-red-700';
        case 'warning':
            return 'bg-yellow-100 border-yellow-500 text-yellow-700';
        default:
            return 'bg-blue-100 border-blue-500 text-blue-700';
    }
}

// Authentication functions
async function checkExistingSession() {
    try {
        if (supabaseClient.isAuthenticated()) {
            const currentUser = await supabaseClient.getCurrentUser();
            const userData = await supabaseClient.getUserData(currentUser.id);
            
            // User is already logged in, redirect to appropriate page
            redirectByRole(userData.cargo);
        }
    } catch (error) {
        console.log('No existing session found');
        // User not logged in, stay on login page
    }
}

function redirectByRole(role) {
    const redirectMap = {
        'proprietario': './proprietario.html',
        'gerente': './gerente.html',
        'funcionario': './funcionario.html',
        'veterinario': './veterinario.html'
    };
    
    const targetPage = redirectMap[role] || './inicio.html';
    window.location.href = targetPage;
}

// Export functions for global access
window.handleLogin = handleLogin;
window.handleForgotPassword = handleForgotPassword;
