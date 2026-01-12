// TypeMagic Popup Script

// Track selected tone
let selectedTone = 'preserve';

// Track undo state for popup textarea
let popupUndoState = {
  originalText: '',
  correctedText: '',
  canUndo: false
};

// Load and display current settings
async function loadStatus() {
  try {
    console.log('🪄 TypeMagic Popup: Loading settings...');
    
    const settings = await chrome.storage.sync.get({
      provider: 'openai',
      openaiKey: '',
      geminiKey: '',
      claudeKey: '',
      fastApiEndpoint: '',
      ollamaEndpoint: 'http://localhost:11434',
      useMarkdown: false
    });
    
    console.log('🪄 TypeMagic Popup: Settings loaded:', settings);
    
    // Update provider dropdown
    const providerSelect = document.getElementById('providerSelect');
    if (providerSelect) {
      providerSelect.value = settings.provider;
    }
  
  // Update markdown toggle
  const markdownToggle = document.getElementById('markdownToggle');
  if (markdownToggle) {
    markdownToggle.checked = settings.useMarkdown;
  }
  
  // Check if API key/endpoint is configured
  let configured = false;
  switch (settings.provider) {
    case 'openai':
      configured = !!settings.openaiKey;
      break;
    case 'gemini':
      configured = !!settings.geminiKey;
      break;
    case 'claude':
      configured = !!settings.claudeKey;
      break;
    case 'fastapi':
      configured = !!settings.fastApiEndpoint;
      break;
    case 'ollama':
      configured = !!settings.ollamaEndpoint;
      break;
  }
  
  const statusEl = document.getElementById('status');
  if (configured) {
    statusEl.textContent = 'Ready';
    statusEl.classList.add('active');
    statusEl.classList.remove('inactive');
  } else {
    statusEl.textContent = 'Not Configured';
    statusEl.classList.add('inactive');
    statusEl.classList.remove('active');
  }
  
  console.log('🪄 TypeMagic Popup: Status display updated');
  } catch (error) {
    console.error('🪄 TypeMagic Popup: Error loading settings:', error);
    document.getElementById('provider').textContent = 'Error';
    document.getElementById('markdown').textContent = 'Error';
    document.getElementById('status').textContent = 'Error';
  }
}

// Wait for DOM to be ready before setting up event listeners
document.addEventListener('DOMContentLoaded', () => {
  // Handle tone button clicks
  document.querySelectorAll('.tone-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      // Remove active class from all buttons
      document.querySelectorAll('.tone-btn').forEach(b => b.classList.remove('active'));
      // Add active class to clicked button
      btn.classList.add('active');
      // Update selected tone
      selectedTone = btn.dataset.tone;
      console.log('🪄 TypeMagic Popup: Tone changed to:', selectedTone);
    });
  });

  // Handle bulletize button
  const bulletizeBtn = document.getElementById('bulletizeBtn');
  if (!bulletizeBtn) {
    console.error('🪄 TypeMagic Popup: bulletizeBtn not found!');
    return;
  }
  
  bulletizeBtn.addEventListener('click', async () => {
  const btn = document.getElementById('bulletizeBtn');
  const textarea = document.getElementById('googleDocsText');
  const originalText = btn.textContent;
  
  if (textarea.value.trim().length === 0) {
    alert('Please paste some text first!');
    return;
  }
  
  btn.textContent = '⏳ Converting...';
  btn.disabled = true;
  
  try {
    const response = await chrome.runtime.sendMessage({
      action: 'correctText',
      text: textarea.value,
      tone: selectedTone,
      bulletize: true
    });
    
    if (response && response.success) {
      await navigator.clipboard.writeText(response.correctedText);
      textarea.value = response.correctedText;
      textarea.select();
      
      btn.textContent = '✅ Converted!';
      setTimeout(() => {
        btn.textContent = originalText;
        btn.disabled = false;
      }, 2000);
    } else {
      throw new Error(response?.error || 'Bulletize failed');
    }
  } catch (error) {
    console.error('Error bulletizing:', error);
    btn.textContent = '❌ Error';
    setTimeout(() => {
      btn.textContent = originalText;
      btn.disabled = false;
    }, 2000);
  }
  });

  // Handle summarize button
  const summarizeBtn = document.getElementById('summarizeBtn');
  if (!summarizeBtn) {
    console.error('🪄 TypeMagic Popup: summarizeBtn not found!');
    return;
  }
  
  summarizeBtn.addEventListener('click', async () => {
    const btn = document.getElementById('summarizeBtn');
    const textarea = document.getElementById('googleDocsText');
    const originalText = btn.textContent;
    
    if (textarea.value.trim().length === 0) {
      alert('Please paste some text first!');
      return;
    }
    
    btn.textContent = '⏳ Summarizing...';
    btn.disabled = true;
    
    try {
      const response = await chrome.runtime.sendMessage({
        action: 'correctText',
        text: textarea.value,
        tone: selectedTone,
        summarize: true
      });
      
      if (response && response.success) {
        await navigator.clipboard.writeText(response.correctedText);
        textarea.value = response.correctedText;
        textarea.select();
        
        btn.textContent = '✅ Summarized!';
        setTimeout(() => {
          btn.textContent = originalText;
          btn.disabled = false;
        }, 2000);
      } else {
        throw new Error(response?.error || 'Summarize failed');
      }
    } catch (error) {
      console.error('Error summarizing:', error);
      btn.textContent = '❌ Error';
      setTimeout(() => {
        btn.textContent = originalText;
        btn.disabled = false;
      }, 2000);
    }
  });

  // Correct text in active tab
  document.getElementById('correctBtn').addEventListener('click', async () => {
    const btn = document.getElementById('correctBtn');
    const textarea = document.getElementById('googleDocsText');
    const originalText = btn.textContent;
    
    btn.textContent = '⏳ Processing...';
    btn.disabled = true;
    
    try {
      // Check if Google Docs textarea has content
      if (textarea.value.trim().length > 0) {
        console.log('🪄 TypeMagic Popup: Correcting text from textarea with tone:', selectedTone);
        
        // Send text directly to background script
        const response = await chrome.runtime.sendMessage({
          action: 'correctText',
          text: textarea.value,
          tone: selectedTone
        });
        
        if (response && response.success) {
          const originalText = textarea.value;
          
          // Store for undo
          popupUndoState = {
            originalText: originalText,
            correctedText: response.correctedText,
            canUndo: true
          };
          updateUndoButton();
          
          // Show diff view
          showDiff(originalText, response.correctedText);
          
          // Copy corrected text to clipboard
          await navigator.clipboard.writeText(response.correctedText);
          
          // Update textarea with corrected text
          textarea.value = response.correctedText;
          textarea.select(); // Select all so user can easily see it
          
          btn.textContent = '✅ Copied! Paste with Ctrl/Cmd+V';
          setTimeout(() => {
            btn.textContent = originalText;
            btn.disabled = false;
          }, 3000);
        } else {
          throw new Error(response?.error || 'Correction failed');
        }
      } else {
        // No textarea content - use standard page correction
        console.log('🪄 TypeMagic Popup: Triggering correction on page with tone:', selectedTone);
        
        const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
        await chrome.tabs.sendMessage(tab.id, { 
          action: 'triggerCorrection',
          tone: selectedTone
        });
        
        btn.textContent = '✅ Done!';
        setTimeout(() => {
          btn.textContent = originalText;
          btn.disabled = false;
        }, 2000);
      }
    } catch (error) {
      console.error('Error triggering correction:', error);
      btn.textContent = '❌ Error';
      setTimeout(() => {
        btn.textContent = originalText;
        btn.disabled = false;
      }, 2000);
    }
  });

  // Open settings page
  document.getElementById('settingsBtn').addEventListener('click', () => {
    chrome.runtime.openOptionsPage();
  });

  // Test connection
  document.getElementById('testBtn').addEventListener('click', async () => {
    const btn = document.getElementById('testBtn');
    const originalText = btn.textContent;
    btn.textContent = '⏳ Testing...';
    btn.disabled = true;
    
    try {
      const response = await chrome.runtime.sendMessage({
        action: 'correctText',
        text: 'test mesage with speling erors'
      });
      
      if (response.success) {
        btn.textContent = '✅ Success!';
        setTimeout(() => {
          btn.textContent = originalText;
          btn.disabled = false;
        }, 2000);
      } else {
        btn.textContent = '❌ Failed';
        alert('Connection test failed: ' + (response.error || 'Unknown error'));
        setTimeout(() => {
          btn.textContent = originalText;
          btn.disabled = false;
        }, 2000);
      }
    } catch (error) {
      btn.textContent = '❌ Error';
      alert('Connection test error: ' + error.message);
      setTimeout(() => {
        btn.textContent = originalText;
        btn.disabled = false;
      }, 2000);
    }
  });

  // Undo button handler
  document.getElementById('undoBtn').addEventListener('click', async () => {
    const btn = document.getElementById('undoBtn');
    const textarea = document.getElementById('googleDocsText');
    
    // Check if we have popup undo state (for textarea corrections)
    if (popupUndoState.canUndo && popupUndoState.originalText) {
      textarea.value = popupUndoState.originalText;
      await navigator.clipboard.writeText(popupUndoState.originalText);
      
      popupUndoState.canUndo = false;
      updateUndoButton();
      
      btn.textContent = '✅ Restored!';
      setTimeout(() => {
        btn.textContent = '↩️ Undo';
      }, 2000);
      return;
    }
    
    // Try to undo on the page
    try {
      const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
      const response = await chrome.tabs.sendMessage(tab.id, { action: 'undoCorrection' });
      
      if (response && response.success) {
        btn.textContent = '✅ Undone!';
        setTimeout(() => {
          btn.textContent = '↩️ Undo';
          btn.disabled = true;
        }, 2000);
      } else {
        btn.textContent = '⚠️ ' + (response?.error || 'Nothing to undo');
        setTimeout(() => {
          btn.textContent = '↩️ Undo';
        }, 2000);
      }
    } catch (error) {
      console.error('Undo error:', error);
      btn.textContent = '❌ Error';
      setTimeout(() => {
        btn.textContent = '↩️ Undo';
      }, 2000);
    }
  });

  // Close diff view button handler
  document.getElementById('closeDiffBtn').addEventListener('click', () => {
    hideDiff();
  });

  // Provider quick-switch handler
  document.getElementById('providerSelect').addEventListener('change', async (e) => {
    const newProvider = e.target.value;
    await chrome.storage.sync.set({ provider: newProvider });
    
    // Update status indicator
    loadStatus();
    
    // Show feedback
    const statusEl = document.getElementById('status');
    statusEl.textContent = 'Provider changed!';
    statusEl.classList.add('active');
    setTimeout(() => loadStatus(), 1500);
  });
  
  // Markdown toggle handler
  document.getElementById('markdownToggle').addEventListener('change', async (e) => {
    const useMarkdown = e.target.checked;
    await chrome.storage.sync.set({ useMarkdown });
  });

  // Keyboard navigation
  document.addEventListener('keydown', (e) => {
    // Enter key to correct text (when not in textarea)
    if (e.key === 'Enter' && !e.shiftKey && document.activeElement.id !== 'googleDocsText') {
      e.preventDefault();
      document.getElementById('correctBtn').click();
    }
    
    // Cmd/Ctrl+Enter to correct text (works anywhere)
    if (e.key === 'Enter' && (e.metaKey || e.ctrlKey)) {
      e.preventDefault();
      document.getElementById('correctBtn').click();
    }
    
    // Cmd/Ctrl+B for bulletize
    if ((e.key === 'b' || e.key === 'B') && (e.metaKey || e.ctrlKey) && !e.shiftKey) {
      e.preventDefault();
      document.getElementById('bulletizeBtn').click();
    }
    
    // Cmd/Ctrl+Shift+S for summarize
    if ((e.key === 's' || e.key === 'S') && (e.metaKey || e.ctrlKey) && e.shiftKey) {
      e.preventDefault();
      document.getElementById('summarizeBtn').click();
    }
    
    // Cmd/Ctrl+Z for undo
    if ((e.key === 'z' || e.key === 'Z') && (e.metaKey || e.ctrlKey) && !e.shiftKey) {
      e.preventDefault();
      document.getElementById('undoBtn').click();
    }
    
    // Escape to close popup
    if (e.key === 'Escape') {
      window.close();
    }
    
    // Number keys 1-3 to select tone
    if (e.key === '1' && !e.metaKey && !e.ctrlKey) {
      document.querySelector('.tone-btn[data-tone="preserve"]').click();
    }
    if (e.key === '2' && !e.metaKey && !e.ctrlKey) {
      document.querySelector('.tone-btn[data-tone="professional"]').click();
    }
    if (e.key === '3' && !e.metaKey && !e.ctrlKey) {
      document.querySelector('.tone-btn[data-tone="casual"]').click();
    }
  });

  // Initialize
  loadStatus();
  checkUndoState();
  loadStats();
  initOnboarding();
  checkOnboarding();
  
  // Focus textarea on popup open for immediate typing
  setTimeout(() => {
    document.getElementById('googleDocsText').focus();
  }, 100);
});

// Update undo button state
function updateUndoButton() {
  const btn = document.getElementById('undoBtn');
  btn.disabled = !popupUndoState.canUndo;
}

// Simple word-level diff algorithm
function computeDiff(original, corrected) {
  const originalWords = original.split(/(\s+)/);
  const correctedWords = corrected.split(/(\s+)/);
  
  const result = [];
  let i = 0, j = 0;
  
  // Simple LCS-based diff
  while (i < originalWords.length || j < correctedWords.length) {
    if (i >= originalWords.length) {
      // Remaining words in corrected are additions
      result.push({ type: 'added', text: correctedWords[j] });
      j++;
    } else if (j >= correctedWords.length) {
      // Remaining words in original are deletions
      result.push({ type: 'removed', text: originalWords[i] });
      i++;
    } else if (originalWords[i] === correctedWords[j]) {
      // Words match
      result.push({ type: 'unchanged', text: originalWords[i] });
      i++;
      j++;
    } else {
      // Look ahead to find if word exists later
      const lookAheadOriginal = originalWords.slice(i + 1, i + 5).indexOf(correctedWords[j]);
      const lookAheadCorrected = correctedWords.slice(j + 1, j + 5).indexOf(originalWords[i]);
      
      if (lookAheadOriginal !== -1 && (lookAheadCorrected === -1 || lookAheadOriginal <= lookAheadCorrected)) {
        // Word was removed from original
        result.push({ type: 'removed', text: originalWords[i] });
        i++;
      } else if (lookAheadCorrected !== -1) {
        // Word was added in corrected
        result.push({ type: 'added', text: correctedWords[j] });
        j++;
      } else {
        // Word was replaced
        result.push({ type: 'removed', text: originalWords[i] });
        result.push({ type: 'added', text: correctedWords[j] });
        i++;
        j++;
      }
    }
  }
  
  return result;
}

// Render diff to HTML
function renderDiff(diffResult) {
  return diffResult.map(item => {
    if (item.type === 'added') {
      return `<span class="diff-added">${escapeHtml(item.text)}</span>`;
    } else if (item.type === 'removed') {
      return `<span class="diff-removed">${escapeHtml(item.text)}</span>`;
    } else {
      return `<span class="diff-unchanged">${escapeHtml(item.text)}</span>`;
    }
  }).join('');
}

// Escape HTML to prevent XSS
function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

// Show diff view
function showDiff(original, corrected) {
  const diffView = document.getElementById('diffView');
  const diffContent = document.getElementById('diffContent');
  
  if (original === corrected) {
    diffContent.innerHTML = '<em style="color: #6b7280;">No changes made - text was already correct!</em>';
  } else {
    const diff = computeDiff(original, corrected);
    diffContent.innerHTML = renderDiff(diff);
  }
  
  diffView.style.display = 'block';
}

// Hide diff view
function hideDiff() {
  document.getElementById('diffView').style.display = 'none';
}

// Check if there's something to undo on the page
async function checkUndoState() {
  try {
    const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
    const response = await chrome.tabs.sendMessage(tab.id, { action: 'getUndoState' });
    
    if (response && response.canUndo) {
      document.getElementById('undoBtn').disabled = false;
    }
  } catch (error) {
    // Page might not have content script, that's okay
    console.log('Could not check undo state:', error.message);
  }
}

// Load and display statistics
async function loadStats() {
  try {
    const stats = await chrome.runtime.sendMessage({ action: 'getStats' });
    if (stats) {
      document.getElementById('statToday').textContent = stats.today || 0;
      document.getElementById('statWeekly').textContent = stats.weekly || 0;
      document.getElementById('statTotal').textContent = stats.total || 0;
    }
  } catch (error) {
    console.log('Could not load stats:', error.message);
  }
}

// Onboarding wizard
let onboardingProvider = null;

async function checkOnboarding() {
  const { onboardingComplete, openaiKey, geminiKey, claudeKey, ollamaEndpoint } = await chrome.storage.sync.get({
    onboardingComplete: false,
    openaiKey: '',
    geminiKey: '',
    claudeKey: '',
    ollamaEndpoint: ''
  });
  
  // Show onboarding if not complete and no API keys configured
  const hasAnyKey = openaiKey || geminiKey || claudeKey;
  if (!onboardingComplete && !hasAnyKey) {
    showOnboarding();
  }
}

function showOnboarding() {
  document.getElementById('onboardingOverlay').style.display = 'flex';
}

function hideOnboarding() {
  document.getElementById('onboardingOverlay').style.display = 'none';
  chrome.storage.sync.set({ onboardingComplete: true });
}

function showOnboardingStep(stepNum) {
  document.querySelectorAll('.onboarding-step').forEach(step => {
    step.style.display = 'none';
  });
  const step = document.querySelector(`.onboarding-step[data-step="${stepNum}"]`);
  if (step) {
    step.style.display = 'block';
  }
}

function initOnboarding() {
  const providerHelp = {
    'openai': 'Get your key at <a href="https://platform.openai.com/api-keys" target="_blank">platform.openai.com</a>',
    'gemini': 'Get your key at <a href="https://makersuite.google.com/app/apikey" target="_blank">Google AI Studio</a>',
    'claude': 'Get your key at <a href="https://console.anthropic.com" target="_blank">console.anthropic.com</a>',
    'ollama': 'Ollama runs locally - no API key needed! Install from <a href="https://ollama.ai" target="_blank">ollama.ai</a>'
  };
  
  // Step 1 -> Step 2
  document.querySelectorAll('.onboarding-step[data-step="1"] .onboarding-next').forEach(btn => {
    btn.addEventListener('click', () => showOnboardingStep(2));
  });
  
  // Provider selection
  document.querySelectorAll('.onboarding-provider-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.onboarding-provider-btn').forEach(b => b.classList.remove('selected'));
      btn.classList.add('selected');
      onboardingProvider = btn.dataset.provider;
      
      const keyInput = document.querySelector('.onboarding-key-input');
      const keyHelp = document.getElementById('onboardingKeyHelp');
      const nextBtn = document.getElementById('onboardingStep2Next');
      
      if (onboardingProvider === 'ollama') {
        keyInput.style.display = 'none';
        keyHelp.innerHTML = providerHelp[onboardingProvider];
        nextBtn.disabled = false;
      } else {
        keyInput.style.display = 'block';
        keyHelp.innerHTML = providerHelp[onboardingProvider];
        nextBtn.disabled = !document.getElementById('onboardingApiKey').value.trim();
      }
    });
  });
  
  // API key input
  document.getElementById('onboardingApiKey').addEventListener('input', (e) => {
    const nextBtn = document.getElementById('onboardingStep2Next');
    nextBtn.disabled = !e.target.value.trim();
  });
  
  // Step 2 -> Step 3
  document.getElementById('onboardingStep2Next').addEventListener('click', async () => {
    if (onboardingProvider) {
      const apiKey = document.getElementById('onboardingApiKey').value.trim();
      
      // Save provider and key
      const settings = { provider: onboardingProvider };
      if (onboardingProvider === 'openai') settings.openaiKey = apiKey;
      else if (onboardingProvider === 'gemini') settings.geminiKey = apiKey;
      else if (onboardingProvider === 'claude') settings.claudeKey = apiKey;
      
      await chrome.storage.sync.set(settings);
      loadStatus(); // Refresh status display
    }
    showOnboardingStep(3);
  });
  
  // Skip button
  document.querySelectorAll('.onboarding-skip').forEach(btn => {
    btn.addEventListener('click', () => showOnboardingStep(3));
  });
  
  // Finish button
  document.querySelectorAll('.onboarding-finish').forEach(btn => {
    btn.addEventListener('click', () => {
      hideOnboarding();
      loadStatus();
    });
  });
}
