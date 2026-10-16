document.addEventListener('DOMContentLoaded', function() {
    const isLoggedIn = window.ChatBotConfig?.isLoggedIn || false;
    const userName   = window.ChatBotConfig?.userName || '';

    // Inject Chatbot HTML
    const logoUrl = window.ChatBotConfig?.logoUrl || '/assets/img/logo.png';
    const chatbotHtml = `
        <div id="chatbot-launcher">
            <div class="cb-logo-area">
                <img class="cb-logo" src="${logoUrl}" alt="Ideal Pearl">
                <span class="chatbot-dot"></span>
            </div>
            <div class="cb-text">
                <span class="cb-title">Chat with Us</span>
                <span class="cb-status">We're online to help!</span>
            </div>
            <div class="cb-divider"></div>
            <div class="cb-icon">
                <svg viewBox="0 0 24 24"><path d="M20 2H4c-1.1 0-2 .9-2 2v18l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zm-7 12H7v-2h6v2zm3-4H7V8h9v2z"/></svg>
            </div>
        </div>
        <div id="chatbot-container">
            <div id="chatbot-header">
                <h4>Ideal Traders AI Assistant</h4>
                <div id="chatbot-close">✕</div>
            </div>
            <div id="chatbot-messages">
                <div class="chat-msg bot">
                    Hello ${userName ? '<b>' + userName + '</b>' : 'there'}! I am your Ideal Traders assistant. How can I help you today?
                    <div class="quick-actions">
                        ${isLoggedIn
                            ? `<button class="quick-btn" onclick="sendQuickMsg('My Orders')">📦 My Orders</button>`
                            : `<button class="quick-btn" onclick="sendQuickMsg('Track Order')">📦 Track Order</button>`
                        }
                        <button class="quick-btn" onclick="sendQuickMsg('Search Products')">🔍 Search Products</button>
                        <button class="quick-btn" onclick="window.open('https://wa.me/' + (window.ChatBotConfig?.whatsappNumber || ''), '_blank')">💬 WhatsApp</button>
                    </div>
                </div>
            </div>
            <div id="chatbot-input-container">
                <input type="text" id="chatbot-input" placeholder="Type your message...">
                <button id="chatbot-send">
                    <svg viewBox="0 0 24 24" width="20" height="20" fill="currentColor"><path d="M2.01 21L23 12 2.01 3 2 10l15 2-15 2z"/></svg>
                </button>
            </div>
        </div>
    `;
    document.body.insertAdjacentHTML('beforeend', chatbotHtml);

    const launcher  = document.getElementById('chatbot-launcher');
    const container = document.getElementById('chatbot-container');
    const closeBtn  = document.getElementById('chatbot-close');
    const input     = document.getElementById('chatbot-input');
    const sendBtn   = document.getElementById('chatbot-send');
    const messages  = document.getElementById('chatbot-messages');

    let ordersLoaded = false; // Prevent fetching multiple times

    launcher.addEventListener('click', () => {
        container.classList.toggle('active');
        if (container.classList.contains('active')) {
            launcher.style.animation = 'none';

            // ✅ Auto-load orders when logged-in user opens chatbot for the first time
            if (isLoggedIn && !ordersLoaded) {
                ordersLoaded = true;
                autoLoadMyOrders();
            }
        } else {
            launcher.style.animation = 'chatbot-float 3s ease-in-out infinite';
        }
    });

    closeBtn.addEventListener('click', () => {
        container.classList.remove('active');
        launcher.style.animation = 'chatbot-float 3s ease-in-out infinite';
    });

    sendBtn.addEventListener('click', sendMessage);
    input.addEventListener('keypress', (e) => {
        if (e.key === 'Enter') sendMessage();
    });

    window.sendQuickMsg = function(msg) {
        input.value = msg;
        sendMessage();
    }

    function appendMessage(text, side) {
        const msgDiv = document.createElement('div');
        msgDiv.className = `chat-msg ${side}`;
        msgDiv.innerHTML = text;
        messages.appendChild(msgDiv);
        messages.scrollTop = messages.scrollHeight;
    }

    /**
     * Auto-fetch recent orders when chatbot opens (logged-in users only).
     */
    function autoLoadMyOrders() {
        const typingDiv = document.createElement('div');
        typingDiv.className = 'chat-msg bot typing-msg';
        typingDiv.innerHTML = '<div class="typing-dots"><span>.</span><span>.</span><span>.</span></div>';
        messages.appendChild(typingDiv);
        messages.scrollTop = messages.scrollHeight;

        let appUrl = document.querySelector('meta[name="app-url"]')?.content || '';
        appUrl = appUrl.replace(/\/$/, '');

        fetch(`${appUrl}/api/v2/local-chatbot/my-orders`, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]')?.content
            }
        })
        .then(res => res.json())
        .then(data => {
            setTimeout(() => {
                typingDiv.remove();
                if (data.logged_in && data.reply) {
                    appendMessage(data.reply, 'bot');
                }
                messages.scrollTop = messages.scrollHeight;
            }, 600);
        })
        .catch(err => {
            typingDiv.remove();
            console.error('Chatbot orders fetch error:', err);
        });
    }

    function sendMessage() {
        const text = input.value.trim();
        if (!text) return;

        appendMessage(text, 'user');
        input.value = '';

        // Show typing indicator
        const typingDiv = document.createElement('div');
        typingDiv.className = 'chat-msg bot typing-msg';
        typingDiv.innerHTML = '<div class="typing-dots"><span>.</span><span>.</span><span>.</span></div>';
        messages.appendChild(typingDiv);
        messages.scrollTop = messages.scrollHeight;

        // API Call to Local AI
        let appUrl = document.querySelector('meta[name="app-url"]')?.content || '';
        appUrl = appUrl.replace(/\/$/, ''); // Remove trailing slash if exists
        
        fetch(`${appUrl}/api/v2/local-chatbot/message`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]')?.content
            },
            body: JSON.stringify({ message: text })
        })
        .then(res => res.json())
        .then(data => {
            // Remove typing indicator and show message with small delay
            setTimeout(() => {
                typingDiv.remove();
                appendMessage(data.reply, 'bot');
                messages.scrollTop = messages.scrollHeight;
            }, 800);
        })
        .catch(err => {
            console.error(err);
            typingDiv.remove();
            appendMessage("Sorry, I'm having trouble connecting right now.", 'bot');
        });
    }
});
