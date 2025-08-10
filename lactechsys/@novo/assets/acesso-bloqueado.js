// acesso-bloqueado.js - Access blocked page functionality

// Initialize page
document.addEventListener('DOMContentLoaded', function() {
    console.log('Acesso bloqueado page loaded');
    
    // Setup event listeners
    setupEventListeners();
    
    // Auto redirect after delay
    setupAutoRedirect();
});

function setupEventListeners() {
    // Back to login button
    const backBtn = document.getElementById('backToLogin');
    if (backBtn) {
        backBtn.addEventListener('click', () => {
            window.location.href = './login.html';
        });
    }
    
    // Contact support button
    const contactBtn = document.getElementById('contactSupport');
    if (contactBtn) {
        contactBtn.addEventListener('click', handleContactSupport);
    }
}

function handleContactSupport() {
    // Could open a modal or redirect to support page
    alert('Entre em contato com o administrador da fazenda para solicitar a liberação do acesso.');
}

function setupAutoRedirect() {
    // Optional: Auto redirect to login after 30 seconds
    let countdown = 30;
    const countdownEl = document.getElementById('countdown');
    
    if (countdownEl) {
        const timer = setInterval(() => {
            countdown--;
            countdownEl.textContent = countdown;
            
            if (countdown <= 0) {
                clearInterval(timer);
                window.location.href = './login.html';
            }
        }, 1000);
    }
}
