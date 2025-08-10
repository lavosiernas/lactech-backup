// index.js - Landing page functionality

// Initialize page
document.addEventListener('DOMContentLoaded', function() {
    console.log('Index page loaded');
    
    // Setup event listeners
    setupEventListeners();
});

function setupEventListeners() {
    // Navigation buttons
    const loginBtn = document.getElementById('loginBtn');
    if (loginBtn) {
        loginBtn.addEventListener('click', () => {
            window.location.href = './login.html';
        });
    }
    
    const registerBtn = document.getElementById('registerBtn');
    if (registerBtn) {
        registerBtn.addEventListener('click', () => {
            window.location.href = './PrimeiroAcesso.html';
        });
    }
    
    // Feature buttons
    const featureBtns = document.querySelectorAll('.feature-btn');
    featureBtns.forEach(btn => {
        btn.addEventListener('click', (e) => {
            e.preventDefault();
            // Could show more info or navigate to specific sections
        });
    });
}
