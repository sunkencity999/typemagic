// TypeMagic Options Script

console.log('🪄 TypeMagic: Options page loaded');

// Default settings
const defaultSettings = {
  provider: 'openai',
  openaiKey: '',
  openaiModel: 'gpt-4o-mini',
  geminiKey: '',
  geminiModel: 'gemini-pro',
  claudeKey: '',
  claudeModel: 'claude-3-5-sonnet-20241022',
  fastApiEndpoint: '',
  ollamaEndpoint: 'http://localhost:11434',
  ollamaModel: 'llama3.2',
  useMarkdown: false,
  systemPrompt: ''
};

// Load settings from storage
async function loadSettings() {
  const settings = await chrome.storage.sync.get(defaultSettings);
  
  // Set provider
  document.querySelector(`input[name="provider"][value="${settings.provider}"]`).checked = true;
  updateProviderUI(settings.provider);
  
  // Set all field values
  document.getElementById('openaiKey').value = settings.openaiKey;
  document.getElementById('openaiModel').value = settings.openaiModel;
  document.getElementById('geminiKey').value = settings.geminiKey;
  document.getElementById('geminiModel').value = settings.geminiModel;
  document.getElementById('claudeKey').value = settings.claudeKey;
  document.getElementById('claudeModel').value = settings.claudeModel;
  document.getElementById('fastApiEndpoint').value = settings.fastApiEndpoint;
  document.getElementById('ollamaEndpoint').value = settings.ollamaEndpoint;
  document.getElementById('ollamaModel').value = settings.ollamaModel;
  document.getElementById('useMarkdown').checked = settings.useMarkdown;
  document.getElementById('systemPrompt').value = settings.systemPrompt;
}

// Save settings to storage
async function saveSettings() {
  const settings = {
    provider: document.querySelector('input[name="provider"]:checked').value,
    openaiKey: document.getElementById('openaiKey').value,
    openaiModel: document.getElementById('openaiModel').value,
    geminiKey: document.getElementById('geminiKey').value,
    geminiModel: document.getElementById('geminiModel').value,
    claudeKey: document.getElementById('claudeKey').value,
    claudeModel: document.getElementById('claudeModel').value,
    fastApiEndpoint: document.getElementById('fastApiEndpoint').value,
    ollamaEndpoint: document.getElementById('ollamaEndpoint').value,
    ollamaModel: document.getElementById('ollamaModel').value,
    useMarkdown: document.getElementById('useMarkdown').checked,
    systemPrompt: document.getElementById('systemPrompt').value
  };
  
  await chrome.storage.sync.set(settings);
  showSaveNotification();
}

// Reset to default settings
async function resetSettings() {
  if (confirm('Are you sure you want to reset all settings to default values?')) {
    await chrome.storage.sync.set(defaultSettings);
    await loadSettings();
    showSaveNotification('Settings reset to defaults');
  }
}

// Update UI based on selected provider
function updateProviderUI(provider) {
  console.log('🪄 TypeMagic: Updating UI for provider:', provider);
  
  // Update status text
  const providerNames = {
    'openai': 'OpenAI',
    'gemini': 'Google Gemini',
    'claude': 'Anthropic Claude',
    'ollama': 'Ollama (Local)',
    'fastapi': 'Custom FastAPI'
  };
  
  const statusElement = document.getElementById('currentProvider');
  if (statusElement) {
    statusElement.textContent = providerNames[provider] || provider;
  }
  
  // Update provider option styling
  document.querySelectorAll('.provider-option').forEach(option => {
    if (option.dataset.provider === provider) {
      option.classList.add('selected');
    } else {
      option.classList.remove('selected');
    }
  });
  
  // Show/hide provider configs
  document.querySelectorAll('.provider-config').forEach(config => {
    if (config.dataset.provider === provider) {
      config.classList.add('active');
      console.log('🪄 TypeMagic: Showing config for', provider);
    } else {
      config.classList.remove('active');
    }
  });
}

// Show save notification
function showSaveNotification(message = 'Settings saved successfully!') {
  const notification = document.getElementById('saveNotification');
  notification.textContent = `✅ ${message}`;
  notification.classList.add('show');
  
  setTimeout(() => {
    notification.classList.remove('show');
  }, 3000);
}

// Initialize
document.addEventListener('DOMContentLoaded', () => {
  // Load settings
  loadSettings();
  
  // Provider selection
  document.querySelectorAll('input[name="provider"]').forEach(radio => {
    radio.addEventListener('change', (e) => {
      updateProviderUI(e.target.value);
    });
  });
  
  // Provider option click handlers
  document.querySelectorAll('.provider-option').forEach(option => {
    option.addEventListener('click', () => {
      const radio = option.querySelector('input[type="radio"]');
      radio.checked = true;
      updateProviderUI(option.dataset.provider);
    });
  });
  
  // Save button
  document.getElementById('saveBtn').addEventListener('click', saveSettings);
  
  // Reset button
  document.getElementById('resetBtn').addEventListener('click', resetSettings);
  
  // Auto-save on input change (with debounce)
  let saveTimeout;
  document.querySelectorAll('input, select, textarea').forEach(input => {
    input.addEventListener('change', () => {
      clearTimeout(saveTimeout);
      saveTimeout = setTimeout(saveSettings, 500);
    });
  });
});
