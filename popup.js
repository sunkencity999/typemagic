// TypeMagic Popup Script

// Track selected tone
let selectedTone = 'preserve';

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
    
    // Update provider display
    const providerNames = {
      'openai': 'OpenAI',
      'gemini': 'Google Gemini',
      'claude': 'Anthropic Claude',
      'fastapi': 'FastAPI',
      'ollama': 'Ollama'
    };
    document.getElementById('provider').textContent = providerNames[settings.provider] || settings.provider;
  
  // Update markdown status
  document.getElementById('markdown').textContent = settings.useMarkdown ? 'Enabled' : 'Disabled';
  
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

  // Initialize
  loadStatus();
});
