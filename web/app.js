class MYMYApp {
    constructor() {
        this.apiBase = 'http://localhost:5000/api';
        this.token = localStorage.getItem('token');
        this.currentConversationId = null;
        this.init();
    }
    
    init() {
        if (!this.token) {
            this.showAuthModal();
        } else {
            this.hideAuthModal();
            this.loadConversations();
        }
        this.setupEventListeners();
    }
    
    // ==================== AUTH ====================
    
    setupEventListeners() {
        // Auth Tabs
        document.querySelectorAll('.tab-btn').forEach(btn => {
            btn.addEventListener('click', (e) => this.switchAuthTab(e.target.dataset.tab));
        });
        
        // Auth Forms
        document.getElementById('login-form')?.addEventListener('submit', (e) => this.handleLogin(e));
        document.getElementById('register-form')?.addEventListener('submit', (e) => this.handleRegister(e));
        
        // Chat
        document.getElementById('chat-form')?.addEventListener('submit', (e) => this.handleSendMessage(e));
        document.getElementById('new-chat-btn')?.addEventListener('click', () => this.createNewConversation());
        document.getElementById('logout-btn')?.addEventListener('click', () => this.logout());
        
        // Auto-resize textarea
        const textarea = document.getElementById('message-input');
        if (textarea) {
            textarea.addEventListener('input', () => this.autoResizeTextarea(textarea));
        }
    }
    
    switchAuthTab(tab) {
        document.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));
        document.querySelectorAll('.auth-form').forEach(form => form.classList.remove('active'));
        
        event.target.classList.add('active');
        document.getElementById(`${tab}-form`).classList.add('active');
    }
    
    async handleLogin(e) {
        e.preventDefault();
        const email = document.getElementById('login-email').value;
        const password = document.getElementById('login-password').value;
        
        try {
            const response = await fetch(`${this.apiBase}/auth/login`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ email, password })
            });
            
            const data = await response.json();
            
            if (response.ok) {
                this.token = data.access_token;
                localStorage.setItem('token', this.token);
                this.hideAuthModal();
                this.loadConversations();
            } else {
                alert(data.error || 'Erreur de connexion');
            }
        } catch (error) {
            console.error('Error:', error);
            alert('Erreur de connexion');
        }
    }
    
    async handleRegister(e) {
        e.preventDefault();
        const username = document.getElementById('register-username').value;
        const email = document.getElementById('register-email').value;
        const password = document.getElementById('register-password').value;
        const confirm = document.getElementById('register-confirm').value;
        
        if (password !== confirm) {
            alert('Les mots de passe ne correspondent pas');
            return;
        }
        
        try {
            const response = await fetch(`${this.apiBase}/auth/register`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ username, email, password })
            });
            
            const data = await response.json();
            
            if (response.ok) {
                this.token = data.access_token;
                localStorage.setItem('token', this.token);
                this.hideAuthModal();
                this.loadConversations();
            } else {
                alert(data.error || 'Erreur d\'inscription');
            }
        } catch (error) {
            console.error('Error:', error);
            alert('Erreur d\'inscription');
        }
    }
    
    logout() {
        this.token = null;
        localStorage.removeItem('token');
        this.showAuthModal();
        document.getElementById('chat-container').innerHTML = '';
        document.getElementById('conversations-container').innerHTML = '';
    }
    
    // ==================== CONVERSATIONS ====================
    
    async loadConversations() {
        try {
            const response = await fetch(`${this.apiBase}/conversations`, {
                headers: { 'Authorization': `Bearer ${this.token}` }
            });
            
            const data = await response.json();
            const container = document.getElementById('conversations-container');
            container.innerHTML = '';
            
            if (data.conversations && data.conversations.length > 0) {
                data.conversations.forEach(conv => {
                    const btn = document.createElement('button');
                    btn.className = 'conversation-item';
                    btn.textContent = conv.title || 'Nouvelle conversation';
                    btn.addEventListener('click', () => this.loadConversation(conv.id));
                    container.appendChild(btn);
                });
            }
        } catch (error) {
            console.error('Error loading conversations:', error);
        }
    }
    
    async createNewConversation() {
        try {
            const response = await fetch(`${this.apiBase}/conversations`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${this.token}`,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ title: 'Nouvelle conversation' })
            });
            
            const data = await response.json();
            this.currentConversationId = data.conversation.id;
            document.getElementById('chat-container').innerHTML = '';
            this.loadConversations();
        } catch (error) {
            console.error('Error creating conversation:', error);
            alert('Erreur lors de la création de la conversation');
        }
    }
    
    async loadConversation(conversationId) {
        this.currentConversationId = conversationId;
        
        try {
            const response = await fetch(`${this.apiBase}/conversations/${conversationId}`, {
                headers: { 'Authorization': `Bearer ${this.token}` }
            });
            
            const data = await response.json();
            const container = document.getElementById('chat-container');
            container.innerHTML = '';
            
            if (data.messages) {
                data.messages.forEach(msg => {
                    this.addMessageToUI(msg.content, msg.role);
                });
            }
            
            // Update active conversation in sidebar
            document.querySelectorAll('.conversation-item').forEach(item => {
                item.classList.remove('active');
            });
            event.target?.classList.add('active');
            
        } catch (error) {
            console.error('Error loading conversation:', error);
        }
    }
    
    // ==================== CHAT ====================
    
    async handleSendMessage(e) {
        e.preventDefault();
        
        if (!this.currentConversationId) {
            await this.createNewConversation();
        }
        
        const textarea = document.getElementById('message-input');
        const message = textarea.value.trim();
        
        if (!message) return;
        
        textarea.value = '';
        this.autoResizeTextarea(textarea);
        
        // Add user message to UI
        this.addMessageToUI(message, 'user');
        
        // Show loading indicator
        this.showLoadingIndicator();
        
        try {
            const response = await fetch(`${this.apiBase}/chat`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${this.token}`,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    message: message,
                    conversation_id: this.currentConversationId
                })
            });
            
            const data = await response.json();
            
            // Remove loading indicator
            this.removeLoadingIndicator();
            
            if (response.ok) {
                this.addMessageToUI(data.response, 'assistant');
            } else {
                this.addMessageToUI(`Erreur: ${data.error}`, 'assistant');
            }
        } catch (error) {
            console.error('Error:', error);
            this.removeLoadingIndicator();
            this.addMessageToUI('Erreur de connexion au serveur', 'assistant');
        }
    }
    
    addMessageToUI(content, role) {
        const container = document.getElementById('chat-container');
        const messageDiv = document.createElement('div');
        messageDiv.className = `message ${role}`;
        
        let html = '';
        if (role === 'assistant') {
            html = `
                <div class="message-avatar">✨</div>
                <div class="message-content">${this.escapeHtml(content)}</div>
            `;
        } else {
            html = `
                <div class="message-content">${this.escapeHtml(content)}</div>
                <div class="message-avatar">👤</div>
            `;
        }
        
        messageDiv.innerHTML = html;
        container.appendChild(messageDiv);
        container.scrollTop = container.scrollHeight;
    }
    
    showLoadingIndicator() {
        const container = document.getElementById('chat-container');
        const loadingDiv = document.createElement('div');
        loadingDiv.className = 'message loading';
        loadingDiv.id = 'loading-indicator';
        loadingDiv.innerHTML = '<div class="loading-dot"></div><div class="loading-dot"></div><div class="loading-dot"></div>';
        container.appendChild(loadingDiv);
        container.scrollTop = container.scrollHeight;
    }
    
    removeLoadingIndicator() {
        const loading = document.getElementById('loading-indicator');
        if (loading) loading.remove();
    }
    
    showAuthModal() {
        document.getElementById('auth-modal').classList.remove('hidden');
    }
    
    hideAuthModal() {
        document.getElementById('auth-modal').classList.add('hidden');
    }
    
    autoResizeTextarea(textarea) {
        textarea.style.height = 'auto';
        textarea.style.height = Math.min(textarea.scrollHeight, 120) + 'px';
    }
    
    escapeHtml(text) {
        const map = {
            '&': '&amp;',
            '<': '&lt;',
            '>': '&gt;',
            '"': '&quot;',
            "'": '&#039;'
        };
        return text.replace(/[&<>"']/g, m => map[m]);
    }
}

// Initialize app when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => new MYMYApp());
} else {
    new MYMYApp();
}
