// TypeMagic Content Script
// Injects correction icons next to text inputs

console.log('🪄 TypeMagic: Content script loaded');

// Listen for messages from popup
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === 'triggerCorrection') {
    // Find the currently focused element or use Google Docs editor
    const activeElement = document.activeElement;
    
    if (isEditableElement(activeElement)) {
      // Correct the focused element
      const dummyIcon = document.createElement('div');
      correctText(activeElement, dummyIcon);
      sendResponse({ success: true });
    } else if (window.location.hostname.includes('docs.google.com')) {
      // Google Docs - correct entire document
      const editor = document.querySelector('.kix-appview-editor');
      if (editor) {
        const icon = document.querySelector('.typemagic-docs-icon') || document.createElement('div');
        correctText(editor, icon);
        sendResponse({ success: true });
      } else {
        sendResponse({ success: false, error: 'No editor found' });
      }
    } else {
      sendResponse({ success: false, error: 'No text field focused. Click in a text field first.' });
    }
    return true;
  }
});

const PROCESSING_CLASS = 'typemagic-processing';

// Store the last selected text (for Google Docs)
let lastSelectedText = '';
let selectionListenerSetup = false;

// Get text from element
function getTextFromElement(element) {
  // Special handling for Google Docs
  if (window.location.hostname.includes('docs.google.com')) {
    const docsText = getGoogleDocsText();
    if (docsText) return docsText;
  }
  
  // For regular elements, check if there's selected text first
  if (element.tagName === 'TEXTAREA' || element.tagName === 'INPUT') {
    // Check if user has selected text in the input/textarea
    const selectionStart = element.selectionStart;
    const selectionEnd = element.selectionEnd;
    
    if (selectionStart !== selectionEnd) {
      const selectedText = element.value.substring(selectionStart, selectionEnd);
      console.log('🪄 TypeMagic: Using selected text from input/textarea, length:', selectedText.length);
      return selectedText;
    }
    
    // No selection, return all text
    console.log('🪄 TypeMagic: No selection, using all text from input/textarea');
    return element.value || '';
  }
  
  if (element.isContentEditable || element.contentEditable === 'true') {
    // Check for selected text in contentEditable
    const selection = window.getSelection();
    if (selection && selection.toString().trim().length > 0) {
      console.log('🪄 TypeMagic: Using selected text from contentEditable, length:', selection.toString().length);
      return selection.toString();
    }
    
    console.log('🪄 TypeMagic: No selection, using all text from contentEditable');
    return element.innerText || element.textContent;
  }
  
  return element.value || '';
}

// Set text in element
async function setTextInElement(element, text) {
  console.log('🪄 TypeMagic: Setting text in element, length:', text.length);
  
  // Special handling for Google Docs
  if (window.location.hostname.includes('docs.google.com')) {
    console.log('🪄 TypeMagic: Using Google Docs clipboard copy');
    await setGoogleDocsText(text);
    return;
  }
  
  // Handle textarea/input with selection
  if (element.tagName === 'TEXTAREA' || element.tagName === 'INPUT') {
    const selectionStart = element.selectionStart;
    const selectionEnd = element.selectionEnd;
    
    if (selectionStart !== selectionEnd) {
      // Replace only the selected portion
      const before = element.value.substring(0, selectionStart);
      const after = element.value.substring(selectionEnd);
      element.value = before + text + after;
      
      // Set cursor position after the inserted text
      const newCursorPos = selectionStart + text.length;
      element.setSelectionRange(newCursorPos, newCursorPos);
      
      console.log('🪄 TypeMagic: Replaced selected text in input/textarea');
    } else {
      // No selection, replace all text
      element.value = text;
      console.log('🪄 TypeMagic: Replaced all text in input/textarea');
    }
  } else if (element.isContentEditable || element.contentEditable === 'true') {
    // Check if there's a selection in contentEditable
    const selection = window.getSelection();
    if (selection && selection.toString().trim().length > 0) {
      // Replace selected text
      const range = selection.getRangeAt(0);
      range.deleteContents();
      range.insertNode(document.createTextNode(text));
      console.log('🪄 TypeMagic: Replaced selected text in contentEditable');
    } else {
      // No selection, replace all
      element.innerText = text;
      console.log('🪄 TypeMagic: Replaced all text in contentEditable');
    }
  } else {
    element.value = text;
  }
  
  // Dispatch input event so the page knows the value changed
  element.dispatchEvent(new Event('input', { bubbles: true }));
  element.dispatchEvent(new Event('change', { bubbles: true }));
  
  console.log('🪄 TypeMagic: Text replacement complete');
}

// Send text to background script for correction
async function correctText(element, icon) {
  const originalText = getTextFromElement(element);
  
  console.log('🪄 TypeMagic: Correcting text, length:', originalText?.length);
  
  if (!originalText || originalText.trim().length === 0) {
    if (window.location.hostname.includes('docs.google.com')) {
      showNotification('⚠️ Please select the text you want to correct first!', 'warning');
    } else {
      showNotification('⚠️ No text to correct', 'warning');
    }
    return;
  }
  
  // Add processing state
  icon.classList.add(PROCESSING_CLASS);
  
  try {
    // Send message to background script
    console.log('🪄 TypeMagic: Sending to background script...');
    const response = await chrome.runtime.sendMessage({
      action: 'correctText',
      text: originalText
    });
    
    console.log('🪄 TypeMagic: Response received:', response);
    
    if (response && response.success) {
      await setTextInElement(element, response.correctedText);
      
      // Show success notification (Google Docs will show its own message)
      if (!window.location.hostname.includes('docs.google.com')) {
        showNotification('✅ Text corrected!', 'success');
      }
    } else {
      // Extract error message properly
      let errorMsg = 'Failed to correct text. Check settings.';
      if (response) {
        if (typeof response.error === 'string') {
          errorMsg = response.error;
        } else if (response.error && response.error.message) {
          errorMsg = response.error.message;
        } else if (response.error) {
          errorMsg = JSON.stringify(response.error);
        }
      }
      showNotification('❌ ' + errorMsg, 'error');
      console.error('🪄 TypeMagic: Error from background:', errorMsg);
      console.error('🪄 TypeMagic: Full response:', JSON.stringify(response));
    }
  } catch (error) {
    console.error('🪄 TypeMagic error:', error);
    showNotification('❌ Error: ' + error.message, 'error');
  } finally {
    icon.classList.remove(PROCESSING_CLASS);
  }
}

// Show temporary notification
function showNotification(message, type = 'info') {
  const notification = document.createElement('div');
  notification.className = `typemagic-notification typemagic-notification-${type}`;
  notification.textContent = message;
  notification.style.maxWidth = '400px';
  notification.style.lineHeight = '1.4';
  document.body.appendChild(notification);
  
  setTimeout(() => {
    notification.classList.add('typemagic-notification-show');
  }, 10);
  
  // Longer duration for longer messages
  const duration = message.length > 50 ? 6000 : 3000;
  
  setTimeout(() => {
    notification.classList.remove('typemagic-notification-show');
    setTimeout(() => notification.remove(), 300);
  }, duration);
}

// Check if element is editable
function isEditableElement(element) {
  if (!element) return false;
  
  // Check if it's a standard input or textarea
  if (element.tagName === 'TEXTAREA') return true;
  if (element.tagName === 'INPUT' && 
      ['text', 'email', 'search', 'url'].includes(element.type)) return true;
  
  // Check if contenteditable
  if (element.isContentEditable || element.contentEditable === 'true') return true;
  
  // Check for Google Docs/complex editors - look for specific attributes
  if (element.getAttribute('role') === 'textbox') return true;
  if (element.classList.contains('kix-lineview-text-block')) return true;
  
  // Google Docs specific: Check if we're inside the document canvas
  if (isInGoogleDocsEditor(element)) return true;
  
  return false;
}

// Check if element or its parents are part of Google Docs editor
function isInGoogleDocsEditor(element) {
  if (!element) return false;
  
  // Check if we're on Google Docs
  if (!window.location.hostname.includes('docs.google.com')) return false;
  
  // Look for Google Docs editor markers
  let current = element;
  while (current && current !== document.body) {
    // Check for various Google Docs editor classes/IDs
    if (current.classList) {
      if (current.classList.contains('kix-appview-editor') ||
          current.classList.contains('kix-page') ||
          current.classList.contains('kix-paginateddocumentplugin') ||
          current.getAttribute('role') === 'textbox') {
        return true;
      }
    }
    current = current.parentElement;
  }
  
  return false;
}

// Get Google Docs text content
function getGoogleDocsText() {
  console.log('🪄 TypeMagic: getGoogleDocsText called');
  console.log('🪄 TypeMagic: lastSelectedText cache:', lastSelectedText ? `"${lastSelectedText.substring(0, 50)}..." (${lastSelectedText.length} chars)` : 'EMPTY');
  
  // First try current selection
  const selection = window.getSelection();
  const currentSelectionText = selection ? selection.toString() : '';
  console.log('🪄 TypeMagic: Current selection:', currentSelectionText ? `"${currentSelectionText.substring(0, 50)}..." (${currentSelectionText.length} chars)` : 'EMPTY');
  
  if (currentSelectionText.trim().length > 0) {
    console.log('🪄 TypeMagic: ✅ Using current selection from Google Docs');
    lastSelectedText = currentSelectionText; // Update cache
    return currentSelectionText;
  }
  
  // If current selection is empty but we have cached text, use that
  // (This handles the case where clicking the icon clears the selection)
  if (lastSelectedText && lastSelectedText.trim().length > 0) {
    console.log('🪄 TypeMagic: ✅ Using cached selection from Google Docs, length:', lastSelectedText.length);
    const textToReturn = lastSelectedText;
    lastSelectedText = ''; // Clear cache after use
    return textToReturn;
  }
  
  // If nothing is selected and no cache, show warning
  console.log('🪄 TypeMagic: ❌ No text selected in Google Docs (no current selection and no cache)');
  return null;
}

// Set Google Docs text - copy to clipboard and show instruction
async function setGoogleDocsText(text) {
  try {
    // Copy corrected text to clipboard
    await navigator.clipboard.writeText(text);
    
    console.log('🪄 TypeMagic: Corrected text copied to clipboard');
    
    // Check if user had text selected
    const selection = window.getSelection();
    const hadSelection = selection && selection.toString().trim().length > 0;
    
    // Show notification with appropriate instructions
    const message = hadSelection 
      ? '✅ Corrected text copied! Just paste with Ctrl/Cmd+V to replace selection'
      : '✅ Text copied to clipboard! Press Ctrl/Cmd+A to select all, then Ctrl/Cmd+V to paste';
    
    showNotification(message, 'success');
    
    return true;
  } catch (error) {
    console.error('🪄 TypeMagic: Error copying to clipboard:', error);
    
    // Fallback: show text in a prompt dialog
    showNotification('⚠️ Copy this corrected text and paste it manually', 'warning');
    
    setTimeout(() => {
      prompt('Copy this corrected text:', text);
    }, 500);
    
    return false;
  }
}

// Set up selection tracking for Google Docs
function setupSelectionTracking() {
  if (selectionListenerSetup) return;
  selectionListenerSetup = true;
  
  console.log('🪄 TypeMagic: Setting up selection tracking');
  
  // For Google Docs, use clipboard reading (user must copy text first)
  if (window.location.hostname.includes('docs.google.com')) {
    console.log('🪄 TypeMagic: Using clipboard-based selection for Google Docs');
    
    // Strategy 1: Listen with capture mode (intercepts before Google Docs)
    const handleCopy = (e) => {
      console.log('🪄 TypeMagic: 📋 Copy event fired!');
      
      // Try to read from event's clipboardData first
      let copiedText = '';
      
      try {
        if (e.clipboardData) {
          copiedText = e.clipboardData.getData('text/plain');
          console.log('🪄 TypeMagic: Got text from clipboardData, length:', copiedText.length);
        }
      } catch (err) {
        console.log('🪄 TypeMagic: Could not read from clipboardData:', err.message);
      }
      
      // If event clipboard didn't work, try async clipboard API
      if (!copiedText || copiedText.trim().length === 0) {
        setTimeout(async () => {
          try {
            copiedText = await navigator.clipboard.readText();
            console.log('🪄 TypeMagic: Got text from navigator.clipboard, length:', copiedText.length);
            
            if (copiedText && copiedText.trim().length > 0) {
              lastSelectedText = copiedText;
              console.log('🪄 TypeMagic: ✅ Captured text from clipboard (async), length:', lastSelectedText.length);
            }
          } catch (err) {
            console.log('🪄 TypeMagic: Could not read from navigator.clipboard:', err.message);
          }
        }, 100);
      } else {
        // Got text from event
        lastSelectedText = copiedText;
        console.log('🪄 TypeMagic: ✅ Captured text from copy event, length:', lastSelectedText.length);
        
        // Clear cache after 30 seconds
        setTimeout(() => {
          if (lastSelectedText === copiedText) {
            console.log('🪄 TypeMagic: Clearing old clipboard cache');
            lastSelectedText = '';
          }
        }, 30000);
      }
    };
    
    // Try multiple attachment points with capture
    document.addEventListener('copy', handleCopy, true); // Capture phase
    window.addEventListener('copy', handleCopy, true); // Also on window
    console.log('🪄 TypeMagic: Copy event listeners attached (capture mode)');
    
    // Strategy 2: Detect Cmd/Ctrl+C keypress and poll clipboard
    document.addEventListener('keydown', async (e) => {
      // Check for Cmd+C (Mac) or Ctrl+C (Windows/Linux)
      if ((e.metaKey || e.ctrlKey) && e.key === 'c') {
        console.log('🪄 TypeMagic: ⌨️ Cmd/Ctrl+C detected! Polling clipboard...');
        
        // Wait a bit for clipboard to populate, then read
        setTimeout(async () => {
          try {
            const clipboardText = await navigator.clipboard.readText();
            if (clipboardText && clipboardText.trim().length > 0) {
              lastSelectedText = clipboardText;
              console.log('🪄 TypeMagic: ✅ Got text from clipboard after keypress, length:', lastSelectedText.length);
              
              // Clear cache after 30 seconds
              setTimeout(() => {
                if (lastSelectedText === clipboardText) {
                  console.log('🪄 TypeMagic: Clearing old clipboard cache');
                  lastSelectedText = '';
                }
              }, 30000);
            }
          } catch (err) {
            console.log('🪄 TypeMagic: Could not read clipboard after keypress:', err.message);
            console.log('🪄 TypeMagic: Trying alternative paste method...');
            
            // Alternative: Create hidden textarea and paste into it
            try {
              const pasteTarget = document.createElement('textarea');
              pasteTarget.style.position = 'fixed';
              pasteTarget.style.left = '-9999px';
              pasteTarget.style.top = '-9999px';
              document.body.appendChild(pasteTarget);
              pasteTarget.focus();
              
              // Try to paste using execCommand (deprecated but still works)
              const success = document.execCommand('paste');
              if (success && pasteTarget.value) {
                lastSelectedText = pasteTarget.value;
                console.log('🪄 TypeMagic: ✅ Got text via execCommand paste, length:', lastSelectedText.length);
                
                // Clear cache after 30 seconds
                setTimeout(() => {
                  if (lastSelectedText === pasteTarget.value) {
                    console.log('🪄 TypeMagic: Clearing old clipboard cache');
                    lastSelectedText = '';
                  }
                }, 30000);
              } else {
                console.log('🪄 TypeMagic: execCommand paste failed or returned empty');
              }
              
              document.body.removeChild(pasteTarget);
            } catch (pasteErr) {
              console.log('🪄 TypeMagic: Alternative paste method failed:', pasteErr.message);
            }
          }
        }, 150); // Wait for clipboard to populate
      }
    }, true); // Capture phase
    console.log('🪄 TypeMagic: Keyboard listener attached for Cmd/Ctrl+C');
    
  } else {
    // For non-Google Docs, use standard selection tracking
    document.addEventListener('selectionchange', () => {
      const selection = window.getSelection();
      const selectedText = selection ? selection.toString() : '';
      
      console.log('🪄 TypeMagic: Selection changed, length:', selectedText.length, 'text:', selectedText.substring(0, 50));
      
      if (selectedText.trim().length > 0) {
        lastSelectedText = selectedText;
        console.log('🪄 TypeMagic: ✅ Stored selected text, length:', lastSelectedText.length);
      }
    });
    
    // Also listen for mouseup to catch selections
    document.addEventListener('mouseup', () => {
      setTimeout(() => {
        const selection = window.getSelection();
        const selectedText = selection ? selection.toString() : '';
        if (selectedText.trim().length > 0) {
          lastSelectedText = selectedText;
          console.log('🪄 TypeMagic: 📝 Text selected via mouseup, length:', lastSelectedText.length);
        }
      }, 10);
    });
  }
}

// Initialize
async function init() {
  console.log('🪄 TypeMagic: Initializing on', window.location.href);
  
  // Set up selection tracking for Google Docs
  setupSelectionTracking();
  
  console.log('🪄 TypeMagic: Initialization complete - use popup button to correct text');
}

// Start when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init);
} else {
  init();
}
