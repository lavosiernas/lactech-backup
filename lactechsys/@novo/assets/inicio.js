// inicio.js - Home page functionality

// Initialize page
document.addEventListener('DOMContentLoaded', function() {
    console.log('Inicio page loaded');
    
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
    
    // Contact form
    const contactForm = document.getElementById('contactForm');
    if (contactForm) {
        contactForm.addEventListener('submit', handleContactSubmit);
    }
}

function handleContactSubmit(e) {
    e.preventDefault();
    
    const formData = new FormData(e.target);
    const data = Object.fromEntries(formData);
    
    // Handle contact form submission
    console.log('Contact form data:', data);
    
    // Show success message
    showNotification('Mensagem enviada com sucesso!', 'success');
    
    // Reset form
    e.target.reset();
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
