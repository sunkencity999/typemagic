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

function setupMacInstallerHelp() {
  const helpButton = document.getElementById('macInstallerHelp');
  const modal = document.getElementById('macInstallerModal');
  const closeBtn = document.getElementById('macInstallerModalClose');

  const isMac = detectPlatform() === 'mac';
  if (helpButton) {
    helpButton.classList.toggle('visible', isMac);
    helpButton.addEventListener('click', () => {
      modal?.classList.add('show');
      document.body.style.overflow = 'hidden';
    });
  }

  const hideModal = () => {
    modal?.classList.remove('show');
    document.body.style.overflow = '';
  };

  closeBtn?.addEventListener('click', hideModal);
  modal?.addEventListener('click', (event) => {
    if (event.target === modal) {
      hideModal();
    }
  });
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

  const installBtn = document.getElementById('ollamaInstallBtn');
  if (installBtn) {
    installBtn.addEventListener('click', handleOllamaInstallClick);
  }

  setupMacInstallerHelp();
});

function handleOllamaInstallClick() {
  const statusEl = document.getElementById('ollamaInstallStatus');
  if (!statusEl) return;

  statusEl.textContent = 'Detecting your operating system...';

  const platform = detectPlatform();
  if (!platform) {
    statusEl.textContent = 'Could not detect OS. Please download Ollama manually from https://ollama.ai';
    return;
  }

  const installer = getInstallerForPlatform(platform);
  if (!installer) {
    statusEl.textContent = 'Unsupported platform. Please install Ollama manually from https://ollama.ai';
    return;
  }

  downloadInstaller(installer);
  statusEl.innerHTML = `✅ Downloaded <code>${installer.filename}</code> (<code>${installer.sha256}</code>).<br>
    Double-click the downloaded installer to finish setup. You can also find it on <a href="https://github.com/sunkencity999/typemagic/releases/tag/v1.0.0" target="_blank">GitHub Releases</a>.`;
}

function detectPlatform() {
  const userAgent = navigator.userAgent.toLowerCase();
  if (userAgent.includes('win')) return 'windows';
  if (userAgent.includes('mac')) return 'mac';
  if (userAgent.includes('linux')) return 'linux';
  return null;
}

function getInstallerForPlatform(platform) {
  const installers = {
    mac: {
      filename: 'TypeMagicOllamaInstaller-macOS.pkg',
      url: 'https://github.com/sunkencity999/typemagic/releases/download/v1.0.0/TypeMagicOllamaInstaller-macOS.pkg',
      sha256: '613b9da944a03fb82fe38ad2d161b1af5d74de63ff5a84c1a2b26dfa2cdd174c'
    },
    linux: {
      filename: 'TypeMagicOllamaInstaller-Linux.sh',
      url: 'https://github.com/sunkencity999/typemagic/releases/download/v1.0.0/TypeMagicOllamaInstaller-Linux.sh',
      sha256: '05a071492ea0974f43328b7e3a17528466dde9c8ff09b07807cfdc264bac0207'
    },
    windows: {
      filename: 'TypeMagicOllamaInstaller-Windows.exe',
      url: 'https://github.com/sunkencity999/typemagic/releases/download/v1.0.0/TypeMagicOllamaInstaller-Windows.exe',
      sha256: '1aeb150219873418e47658f23bdae1a517f73e846677920c0b6f3b3e9a6e34ab'
    }
  };

  return installers[platform] || null;
}

function downloadInstaller({ filename, url }) {
  const link = document.createElement('a');
  link.href = url;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
}
