// primeiroAcesso.js - First access registration functionality

import { supabaseClient } from './supabase-client.js';

// Supabase configuration
const SUPABASE_CONFIG = {
    url: 'https://mauioyodoxmuzqweaasc.supabase.co',
    key: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1hdWlveW9kb3htdXpxd2VhYXNjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ3NzYyNzksImV4cCI6MjA3MDM1MjI3OX0.m2nZ_5Vbi9aBz1vZ_oA-JHsd_yqD9brJXjnr39k7Ajc'
};

let currentStep = 1;
const totalSteps = 3;

// Initialize page
document.addEventListener('DOMContentLoaded', async function() {
    console.log('PrimeiroAcesso page loaded');
    
    try {
        // Initialize Supabase client
        await supabaseClient.initialize(SUPABASE_CONFIG.url, SUPABASE_CONFIG.key);
        
        // Setup event listeners
        setupEventListeners();
        
        // Initialize first step
        showStep(1);
        
    } catch (error) {
        console.error('Error initializing first access page:', error);
        showNotification('Erro ao carregar página de cadastro', 'error');
    }
});

function setupEventListeners() {
    // Step navigation buttons
    const nextBtns = document.querySelectorAll('.next-step');
    const prevBtns = document.querySelectorAll('.prev-step');
    
    nextBtns.forEach(btn => {
        btn.addEventListener('click', nextStep);
    });
    
    prevBtns.forEach(btn => {
        btn.addEventListener('click', prevStep);
    });
    
    // Form submissions
    const farmForm = document.getElementById('farmForm');
    if (farmForm) {
        farmForm.addEventListener('submit', handleFarmRegistration);
    }
    
    const userForm = document.getElementById('userForm');
    if (userForm) {
        userForm.addEventListener('submit', handleUserRegistration);
    }
    
    // CNPJ formatting
    const cnpjInput = document.getElementById('cnpj');
    if (cnpjInput) {
        cnpjInput.addEventListener('input', formatCNPJ);
    }
    
    // Phone formatting
    const phoneInput = document.getElementById('phone');
    if (phoneInput) {
        phoneInput.addEventListener('input', formatPhone);
    }
}

function showStep(step) {
    // Hide all steps
    document.querySelectorAll('.step').forEach(stepEl => {
        stepEl.classList.add('hidden');
    });
    
    // Show current step
    const currentStepEl = document.getElementById(`step-${step}`);
    if (currentStepEl) {
        currentStepEl.classList.remove('hidden');
    }
    
    // Update progress bar
    updateProgressBar(step);
    
    currentStep = step;
}

function nextStep() {
    if (currentStep < totalSteps) {
        if (validateCurrentStep()) {
            showStep(currentStep + 1);
        }
    }
}

function prevStep() {
    if (currentStep > 1) {
        showStep(currentStep - 1);
    }
}

function validateCurrentStep() {
    const currentStepEl = document.getElementById(`step-${currentStep}`);
    const form = currentStepEl.querySelector('form');
    
    if (form) {
        const formData = new FormData(form);
        const requiredFields = form.querySelectorAll('[required]');
        
        for (let field of requiredFields) {
            if (!field.value.trim()) {
                showNotification(`Por favor, preencha o campo: ${field.labels[0]?.textContent || field.name}`, 'warning');
                field.focus();
                return false;
            }
        }
        
        // Additional validation for specific steps
        if (currentStep === 1) {
            return validateFarmData();
        } else if (currentStep === 2) {
            return validateUserData();
        }
    }
    
    return true;
}

function validateFarmData() {
    const cnpj = document.getElementById('cnpj').value;
    const farmName = document.getElementById('farmName').value;
    
    if (!isValidCNPJ(cnpj)) {
        showNotification('CNPJ inválido', 'error');
        return false;
    }
    
    if (farmName.length < 3) {
        showNotification('Nome da fazenda deve ter pelo menos 3 caracteres', 'error');
        return false;
    }
    
    return true;
}

function validateUserData() {
    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;
    const confirmPassword = document.getElementById('confirmPassword').value;
    
    if (!isValidEmail(email)) {
        showNotification('Email inválido', 'error');
        return false;
    }
    
    if (password.length < 6) {
        showNotification('Senha deve ter pelo menos 6 caracteres', 'error');
        return false;
    }
    
    if (password !== confirmPassword) {
        showNotification('Senhas não coincidem', 'error');
        return false;
    }
    
    return true;
}

function updateProgressBar(step) {
    const progress = (step / totalSteps) * 100;
    const progressBar = document.querySelector('.progress-bar');
    if (progressBar) {
        progressBar.style.width = `${progress}%`;
    }
    
    // Update step indicators
    document.querySelectorAll('.step-indicator').forEach((indicator, index) => {
        const stepNumber = index + 1;
        if (stepNumber < step) {
            indicator.classList.add('completed');
            indicator.classList.remove('active');
        } else if (stepNumber === step) {
            indicator.classList.add('active');
            indicator.classList.remove('completed');
        } else {
            indicator.classList.remove('active', 'completed');
        }
    });
}

async function handleFarmRegistration(e) {
    e.preventDefault();
    
    const formData = new FormData(e.target);
    const farmData = Object.fromEntries(formData);
    
    try {
        // Farm registration logic will be implemented when Supabase is reconnected
        console.log('Farm registration data:', farmData);
        
        // Simulate API call
        await new Promise(resolve => setTimeout(resolve, 1000));
        
        showNotification('Dados da fazenda salvos com sucesso!', 'success');
        nextStep();
        
    } catch (error) {
        console.error('Erro no cadastro da fazenda:', error);
        showNotification('Erro no cadastro da fazenda: ' + error.message, 'error');
    }
}

async function handleUserRegistration(e) {
    e.preventDefault();
    
    const formData = new FormData(e.target);
    const userData = Object.fromEntries(formData);
    
    try {
        // User registration logic will be implemented when Supabase is reconnected
        console.log('User registration data:', userData);
        
        // Simulate API call
        await new Promise(resolve => setTimeout(resolve, 1000));
        
        showNotification('Usuário criado com sucesso!', 'success');
        nextStep();
        
    } catch (error) {
        console.error('Erro no cadastro do usuário:', error);
        showNotification('Erro no cadastro do usuário: ' + error.message, 'error');
    }
}

function formatCNPJ(e) {
    let value = e.target.value.replace(/\D/g, '');
    value = value.replace(/^(\d{2})(\d)/, '$1.$2');
    value = value.replace(/^(\d{2})\.(\d{3})(\d)/, '$1.$2.$3');
    value = value.replace(/\.(\d{3})(\d)/, '.$1/$2');
    value = value.replace(/(\d{4})(\d)/, '$1-$2');
    e.target.value = value;
}

function formatPhone(e) {
    let value = e.target.value.replace(/\D/g, '');
    value = value.replace(/^(\d{2})(\d)/, '($1) $2');
    value = value.replace(/(\d{5})(\d)/, '$1-$2');
    e.target.value = value;
}

function isValidCNPJ(cnpj) {
    cnpj = cnpj.replace(/\D/g, '');
    
    if (cnpj.length !== 14) return false;
    if (/^(\d)\1+$/.test(cnpj)) return false;
    
    // CNPJ validation algorithm
    let sum = 0;
    let weight = 2;
    
    for (let i = 11; i >= 0; i--) {
        sum += parseInt(cnpj[i]) * weight;
        weight = weight === 9 ? 2 : weight + 1;
    }
    
    let remainder = sum % 11;
    let digit1 = remainder < 2 ? 0 : 11 - remainder;
    
    if (parseInt(cnpj[12]) !== digit1) return false;
    
    sum = 0;
    weight = 2;
    
    for (let i = 12; i >= 0; i--) {
        sum += parseInt(cnpj[i]) * weight;
        weight = weight === 9 ? 2 : weight + 1;
    }
    
    remainder = sum % 11;
    let digit2 = remainder < 2 ? 0 : 11 - remainder;
    
    return parseInt(cnpj[13]) === digit2;
}

function isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
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

// Export functions for global access
window.nextStep = nextStep;
window.prevStep = prevStep;
