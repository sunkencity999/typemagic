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

  const installBtn = document.getElementById('ollamaInstallBtn');
  if (installBtn) {
    installBtn.addEventListener('click', handleOllamaInstallClick);
  }
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

  const script = buildInstallScript(platform);
  if (!script) {
    statusEl.textContent = 'Unsupported platform. Please install Ollama manually from https://ollama.ai';
    return;
  }

  downloadScript(script);
  statusEl.innerHTML = `✅ Downloaded <code>${script.filename}</code>.<br>Open a terminal, run it (e.g. <code>${script.runCommand}</code>), and keep the window open while Ollama serves llama3.1:8b.`;
}

function detectPlatform() {
  const userAgent = navigator.userAgent.toLowerCase();
  if (userAgent.includes('win')) return 'windows';
  if (userAgent.includes('mac')) return 'mac';
  if (userAgent.includes('linux')) return 'linux';
  return null;
}

function buildInstallScript(platform) {
  switch (platform) {
    case 'mac':
      return {
        filename: 'install-ollama-macos.sh',
        runCommand: 'sh install-ollama-macos.sh',
        content: `#!/usr/bin/env bash
set -euo pipefail

command -v curl >/dev/null 2>&1 || { echo "curl is required"; exit 1; }

if command -v ollama >/dev/null 2>&1; then
  echo "✅ Ollama already installed. Skipping download."
else
  echo "➡️ Installing Ollama..."
  curl -fsSL https://ollama.com/install.sh | sh
fi

PROFILE="$HOME/.zshrc"
if [[ "$SHELL" == *"bash"* ]]; then PROFILE="$HOME/.bashrc"; fi
LINE='export OLLAMA_ORIGINS="chrome-extension://*"'
touch "$PROFILE"
grep -F "$LINE" "$PROFILE" >/dev/null 2>&1 || echo "$LINE" >> "$PROFILE"
export OLLAMA_ORIGINS="chrome-extension://*"
echo "✅ OLLAMA_ORIGINS set (and persisted in $PROFILE)."

echo "➡️ Pulling llama3.1:8b..."
ollama pull llama3.1:8b

if curl -sf http://127.0.0.1:11434/api/version >/dev/null; then
  echo "✅ Ollama is already running. No need to start a new server."
else
  echo "➡️ Starting Ollama (logs: /tmp/ollama.log)..."
  nohup env OLLAMA_ORIGINS="chrome-extension://*" ollama serve >/tmp/ollama.log 2>&1 &
  echo "✅ Ollama is starting. Keep this terminal open if prompted."
fi
`
      };
    case 'linux':
      return {
        filename: 'install-ollama-linux.sh',
        runCommand: 'sh install-ollama-linux.sh',
        content: `#!/usr/bin/env bash
set -euo pipefail

command -v curl >/dev/null 2>&1 || { echo "curl is required"; exit 1; }

if command -v ollama >/dev/null 2>&1; then
  echo "✅ Ollama already installed. Skipping download."
else
  echo "➡️ Installing Ollama..."
  curl -fsSL https://ollama.com/install.sh | sh
fi

PROFILE="$HOME/.bashrc"
LINE='export OLLAMA_ORIGINS="chrome-extension://*"'
touch "$PROFILE"
grep -F "$LINE" "$PROFILE" >/dev/null 2>&1 || echo "$LINE" >> "$PROFILE"
export OLLAMA_ORIGINS="chrome-extension://*"
echo "✅ OLLAMA_ORIGINS set (and persisted in $PROFILE)."

echo "➡️ Pulling llama3.1:8b..."
ollama pull llama3.1:8b

if curl -sf http://127.0.0.1:11434/api/version >/dev/null; then
  echo "✅ Ollama is already running. No need to start a new server."
else
  echo "➡️ Starting Ollama (logs: /tmp/ollama.log)..."
  nohup env OLLAMA_ORIGINS="chrome-extension://*" ollama serve >/tmp/ollama.log 2>&1 &
  echo "✅ Ollama is starting. Keep this terminal open if prompted."
fi
`
      };
    case 'windows':
      return {
        filename: 'install-ollama-windows.ps1',
        runCommand: 'powershell -ExecutionPolicy Bypass -File install-ollama-windows.ps1',
        content: `Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (Get-Command ollama -ErrorAction SilentlyContinue) {
  Write-Host '✅ Ollama already installed. Skipping download.'
} else {
  Write-Host '➡️ Installing Ollama via winget...'
  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error 'winget is required. Install it from https://learn.microsoft.com/windows/package-manager/winget/'
  }
  winget install -e --id Ollama.Ollama --source winget -h
}

[Environment]::SetEnvironmentVariable('OLLAMA_ORIGINS', 'chrome-extension://*', 'User')
$env:OLLAMA_ORIGINS = 'chrome-extension://*'
Write-Host '✅ OLLAMA_ORIGINS set for the current and future sessions.'

Write-Host '➡️ Pulling llama3.1:8b...'
ollama pull llama3.1:8b

try {
  Invoke-WebRequest -Uri 'http://127.0.0.1:11434/api/version' -Method Get -TimeoutSec 5 | Out-Null
  Write-Host '✅ Ollama is already running. No need to start a new server.'
} catch {
  Write-Host '➡️ Starting Ollama in the background...'
  Start-Process -FilePath 'ollama' -ArgumentList 'serve' -WindowStyle Hidden -Environment @{ OLLAMA_ORIGINS = 'chrome-extension://*' }
  Write-Host '✅ Ollama is starting with llama3.1:8b ready.'
}
`
      };
    default:
      return null;
  }
}

function downloadScript({ filename, content }) {
  const blob = new Blob([content], { type: 'text/plain;charset=utf-8' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}
