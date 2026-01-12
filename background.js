// TypeMagic Background Service Worker
// Handles API calls to various AI providers

console.log('🪄 TypeMagic: Background service worker loaded');

// Error codes and user-friendly messages
const ERROR_MESSAGES = {
  'NETWORK_ERROR': 'Network error. Check your internet connection.',
  'API_KEY_MISSING': 'API key not configured. Open Settings to add your key.',
  'API_KEY_INVALID': 'Invalid API key. Please check your key in Settings.',
  'RATE_LIMITED': 'Rate limited. Please wait a moment and try again.',
  'SERVER_ERROR': 'Server error. The AI provider is having issues.',
  'TIMEOUT': 'Request timed out. Try again or use a faster model.',
  'QUOTA_EXCEEDED': 'API quota exceeded. Check your billing or try a different provider.',
  'MODEL_NOT_FOUND': 'Model not found. Check your model name in Settings.',
  'CONTENT_FILTERED': 'Content was filtered by the AI provider.',
  'UNKNOWN': 'An unexpected error occurred. Please try again.'
};

// Retry configuration
const RETRY_CONFIG = {
  maxRetries: 2,
  retryDelay: 1000, // ms
  retryableStatuses: [429, 500, 502, 503, 504]
};

// Parse error response and return user-friendly message
function parseErrorResponse(error, provider) {
  const errorStr = error.message || error.toString();
  
  // Check for common error patterns
  if (errorStr.includes('Failed to fetch') || errorStr.includes('NetworkError')) {
    return { code: 'NETWORK_ERROR', message: ERROR_MESSAGES.NETWORK_ERROR };
  }
  if (errorStr.includes('401') || errorStr.includes('Unauthorized') || errorStr.includes('invalid_api_key')) {
    return { code: 'API_KEY_INVALID', message: ERROR_MESSAGES.API_KEY_INVALID };
  }
  if (errorStr.includes('429') || errorStr.includes('rate_limit') || errorStr.includes('Rate limit')) {
    return { code: 'RATE_LIMITED', message: ERROR_MESSAGES.RATE_LIMITED };
  }
  if (errorStr.includes('500') || errorStr.includes('502') || errorStr.includes('503') || errorStr.includes('504')) {
    return { code: 'SERVER_ERROR', message: `${provider} server error. Try again in a moment.` };
  }
  if (errorStr.includes('timeout') || errorStr.includes('Timeout')) {
    return { code: 'TIMEOUT', message: ERROR_MESSAGES.TIMEOUT };
  }
  if (errorStr.includes('quota') || errorStr.includes('billing') || errorStr.includes('insufficient_quota')) {
    return { code: 'QUOTA_EXCEEDED', message: ERROR_MESSAGES.QUOTA_EXCEEDED };
  }
  if (errorStr.includes('model') && (errorStr.includes('not found') || errorStr.includes('does not exist'))) {
    return { code: 'MODEL_NOT_FOUND', message: ERROR_MESSAGES.MODEL_NOT_FOUND };
  }
  if (errorStr.includes('content_filter') || errorStr.includes('flagged')) {
    return { code: 'CONTENT_FILTERED', message: ERROR_MESSAGES.CONTENT_FILTERED };
  }
  
  // Return original error if no pattern matched
  return { code: 'UNKNOWN', message: errorStr.substring(0, 200) };
}

// Retry wrapper for API calls
async function withRetry(fn, provider) {
  let lastError;
  
  for (let attempt = 0; attempt <= RETRY_CONFIG.maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;
      const errorStr = error.message || '';
      
      // Check if this is a retryable error
      const isRetryable = RETRY_CONFIG.retryableStatuses.some(status => 
        errorStr.includes(status.toString())
      ) || errorStr.includes('rate_limit') || errorStr.includes('Rate limit');
      
      if (isRetryable && attempt < RETRY_CONFIG.maxRetries) {
        console.log(`🪄 TypeMagic: Retry attempt ${attempt + 1} for ${provider} after error:`, errorStr);
        await new Promise(resolve => setTimeout(resolve, RETRY_CONFIG.retryDelay * (attempt + 1)));
        continue;
      }
      
      // Not retryable or max retries reached
      break;
    }
  }
  
  // Parse and throw user-friendly error
  const parsed = parseErrorResponse(lastError, provider);
  throw new Error(parsed.message);
}

// Statistics tracking
async function incrementStats() {
  const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD
  const stats = await chrome.storage.local.get({
    totalCorrections: 0,
    dailyCorrections: {},
    weeklyCorrections: 0,
    lastResetDate: today
  });
  
  // Reset weekly count if it's a new week (Monday)
  const lastReset = new Date(stats.lastResetDate);
  const now = new Date();
  const daysSinceReset = Math.floor((now - lastReset) / (1000 * 60 * 60 * 24));
  if (daysSinceReset >= 7 || (now.getDay() === 1 && lastReset.getDay() !== 1)) {
    stats.weeklyCorrections = 0;
    stats.lastResetDate = today;
  }
  
  // Increment counters
  stats.totalCorrections++;
  stats.weeklyCorrections++;
  stats.dailyCorrections[today] = (stats.dailyCorrections[today] || 0) + 1;
  
  // Clean up old daily stats (keep last 30 days)
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
  const cutoffDate = thirtyDaysAgo.toISOString().split('T')[0];
  for (const date of Object.keys(stats.dailyCorrections)) {
    if (date < cutoffDate) {
      delete stats.dailyCorrections[date];
    }
  }
  
  await chrome.storage.local.set(stats);
  updateBadge(stats.dailyCorrections[today]);
  
  return stats;
}

function updateBadge(count) {
  if (count > 0) {
    chrome.action.setBadgeText({ text: count.toString() });
    chrome.action.setBadgeBackgroundColor({ color: '#e07a5f' }); // Accent color
  } else {
    chrome.action.setBadgeText({ text: '' });
  }
}

// Initialize badge on startup
chrome.storage.local.get({ dailyCorrections: {} }).then(({ dailyCorrections }) => {
  const today = new Date().toISOString().split('T')[0];
  const todayCount = dailyCorrections[today] || 0;
  updateBadge(todayCount);
});

// Listen for messages from content script
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  console.log('🪄 TypeMagic: Received message:', request.action);
  
  if (request.action === 'getStats') {
    chrome.storage.local.get({
      totalCorrections: 0,
      dailyCorrections: {},
      weeklyCorrections: 0
    }).then(stats => {
      const today = new Date().toISOString().split('T')[0];
      sendResponse({
        total: stats.totalCorrections,
        today: stats.dailyCorrections[today] || 0,
        weekly: stats.weeklyCorrections
      });
    });
    return true;
  }
  
  if (request.action === 'correctText') {
    handleTextCorrection(request.text, request.tone, request.bulletize, request.summarize)
      .then(async correctedText => {
        console.log('🪄 TypeMagic: Correction successful');
        await incrementStats();
        sendResponse({ success: true, correctedText });
      })
      .catch(error => {
        console.error('🪄 TypeMagic: Correction error:', error);
        sendResponse({ success: false, error: error.message });
      });
    return true; // Keep channel open for async response
  }
});

// Main function to handle text correction
async function handleTextCorrection(text, tone = 'preserve', bulletize = false, summarize = false) {
  console.log('🪄 TypeMagic: Starting text correction, text length:', text.length, 'tone:', tone, 'bulletize:', bulletize, 'summarize:', summarize);
  
  // Get settings from storage
  const settings = await chrome.storage.sync.get({
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
    systemPrompt: '',
    customDictionary: []
  });
  
  console.log('🪄 TypeMagic: Using provider:', settings.provider);
  console.log('🪄 TypeMagic: Markdown enabled:', settings.useMarkdown);
  console.log('🪄 TypeMagic: Custom dictionary entries:', settings.customDictionary?.length || 0);
  
  // Build the prompt
  const prompt = buildPrompt(text, settings.useMarkdown, settings.systemPrompt, tone, bulletize, summarize, settings.customDictionary);
  
  // Provider display names for error messages
  const providerNames = {
    'openai': 'OpenAI',
    'gemini': 'Google Gemini',
    'claude': 'Anthropic Claude',
    'fastapi': 'FastAPI',
    'ollama': 'Ollama'
  };
  const providerName = providerNames[settings.provider] || settings.provider;
  
  // Call appropriate API based on provider with retry logic
  switch (settings.provider) {
    case 'openai':
      return await withRetry(() => callOpenAI(prompt, settings.openaiKey, settings.openaiModel), providerName);
    case 'gemini':
      return await withRetry(() => callGemini(prompt, settings.geminiKey, settings.geminiModel), providerName);
    case 'claude':
      return await withRetry(() => callClaude(prompt, settings.claudeKey, settings.claudeModel), providerName);
    case 'fastapi':
      return await withRetry(() => callFastAPI(prompt, settings.fastApiEndpoint), providerName);
    case 'ollama':
      return await withRetry(() => callOllama(prompt, settings.ollamaEndpoint, settings.ollamaModel), providerName);
    default:
      throw new Error('Invalid provider selected. Please choose a provider in Settings.');
  }
}

// Build the correction prompt
function buildPrompt(text, useMarkdown, customSystemPrompt, tone = 'preserve', bulletize = false, summarize = false, customDictionary = []) {
  // Base instructions for all tones
  let baseInstructions = `You are a precise text correction assistant.`;
  
  // Build dictionary instructions if there are custom terms
  let dictionaryInstructions = '';
  if (customDictionary && customDictionary.length > 0) {
    const preserveTerms = customDictionary.filter(e => e.action === 'preserve').map(e => e.term);
    const ignoreTerms = customDictionary.filter(e => e.action === 'ignore').map(e => e.term);
    const replaceTerms = customDictionary.filter(e => e.action === 'replace');
    
    const parts = [];
    
    if (preserveTerms.length > 0) {
      parts.push(`ALWAYS preserve these terms exactly as written (do not change capitalization or spelling): ${preserveTerms.join(', ')}`);
    }
    
    if (ignoreTerms.length > 0) {
      parts.push(`IGNORE these terms completely (do not flag as errors or modify): ${ignoreTerms.join(', ')}`);
    }
    
    if (replaceTerms.length > 0) {
      const replacements = replaceTerms.map(e => `"${e.term}" → "${e.replacement}"`).join(', ');
      parts.push(`ALWAYS replace these terms: ${replacements}`);
    }
    
    if (parts.length > 0) {
      dictionaryInstructions = '\n\nCUSTOM DICTIONARY RULES:\n' + parts.map((p, i) => `${i + 1}. ${p}`).join('\n');
    }
  }
  
  // Tone-specific instructions
  let toneInstructions = '';
  
  if (summarize) {
    toneInstructions = `

Your task: Create a clear, concise summary of the text while fixing any errors.

Rules:
1. Fix spelling, grammar, and punctuation errors in your summary
2. Capture the main points and key information
3. Keep the summary between 2-5 sentences (or 20-30% of original length for very long texts)
4. Preserve the original meaning and intent
5. Use clear, professional language
6. Organize information logically
${useMarkdown ? '7. Use Markdown formatting (bold, italic) to emphasize key points if helpful' : '7. Return plain text without special formatting'}

IMPORTANT: Create a flowing summary, not bullet points. Write it as a coherent paragraph or two.

Return ONLY the summary. No explanations, no preamble.`;
  } else if (bulletize) {
    toneInstructions = `

Your task: Convert the text into clear, concise bullet points while fixing any errors.

Rules:
1. Fix spelling, grammar, and punctuation errors
2. Convert paragraphs into bullet points
3. Each bullet should be a complete, clear statement
4. Preserve the original meaning and key information
5. Keep the user's voice and terminology
${useMarkdown ? '6. Use Markdown formatting (-, *, bold, italic) for bullets' : '6. Use simple dashes (-) or asterisks (*) for bullets'}

Return ONLY the bulletized text. No explanations, no preamble.`;
  } else if (tone === 'professional') {
    toneInstructions = `

Your task: Fix errors and elevate the text to a more professional tone while preserving the core message.

Rules:
1. Fix spelling, grammar, and punctuation errors
2. PRESERVE all existing paragraph breaks (blank lines between paragraphs) - do NOT remove them
3. If text is one long paragraph (a wall of text), ADD paragraph breaks to separate different topics/ideas
4. Replace casual language with professional equivalents (e.g., "gonna" → "going to", "kinda" → "somewhat")
5. Remove slang and overly casual expressions
6. Maintain a respectful, business-appropriate tone
7. Keep the original meaning and intent
8. Do NOT change what the user is saying, only HOW they say it
${useMarkdown ? '9. Use Markdown formatting (bold, italic, headers, lists) to enhance readability' : '9. Return plain text without special formatting'}

Return ONLY the corrected text. No explanations, no preamble.`;
  } else if (tone === 'casual') {
    toneInstructions = `

Your task: Fix errors and make the text more conversational and friendly.

Rules:
1. Fix spelling, grammar, and punctuation errors
2. PRESERVE all existing paragraph breaks (blank lines between paragraphs) - do NOT remove them
3. If text is one long paragraph (a wall of text), ADD paragraph breaks to separate different topics/ideas
4. Make formal language more conversational (e.g., "utilize" → "use", "therefore" → "so")
5. Add conversational warmth where appropriate
6. Keep it natural and approachable
7. Preserve the original meaning
${useMarkdown ? '8. Use Markdown formatting (bold, italic, headers, lists) to enhance readability' : '8. Return plain text without special formatting'}

Return ONLY the corrected text. No explanations, no preamble.`;
  } else { // tone === 'preserve'
    toneInstructions = `

Your task: Fix ALL spelling, grammar, and punctuation errors while preserving the user's unique voice and style.

Rules:
1. You MUST fix ALL spelling errors (e.g., "happnionnijn" → "happening", "teh" → "the")
2. You MUST fix ALL grammar errors (e.g., "Hell o" → "Hello", "I doesnt" → "I don't")
3. You MUST fix ALL punctuation errors (missing commas, periods, apostrophes, etc.)
4. PRESERVE all existing paragraph breaks (blank lines between paragraphs) - do NOT remove them
5. If text is one long paragraph (a wall of text), ADD paragraph breaks to separate different topics/ideas
6. PRESERVE the user's unique voice, tone, and personality
7. PRESERVE informal language, slang, and casual expressions (e.g., keep "gonna", "kinda", "lol", "bruh")
8. Do NOT rewrite sentences unless they contain errors
9. Do NOT change vocabulary to sound more formal or sophisticated
10. Do NOT add new information or change what the user is saying
11. Do NOT homogenize the writing style - keep their individuality
${useMarkdown ? '12. Use Markdown formatting (bold, italic, headers, lists) to enhance readability' : '12. Return plain text without special formatting'}

IMPORTANT: Your job is to FIX ERRORS, not to rewrite. Correct every mistake, keep all existing paragraph breaks, but keep the voice exactly the same.

Return ONLY the corrected text. No explanations, no preamble.`;
  }
  
  let systemPrompt = customSystemPrompt || (baseInstructions + toneInstructions);
  
  // Append dictionary instructions to any prompt (custom or default)
  if (dictionaryInstructions) {
    systemPrompt += dictionaryInstructions;
  }
  
  return {
    system: systemPrompt,
    user: text
  };
}

// OpenAI API
async function callOpenAI(prompt, apiKey, model) {
  if (!apiKey) {
    throw new Error('OpenAI API key not configured');
  }
  
  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${apiKey}`
    },
    body: JSON.stringify({
      model: model,
      messages: [
        { role: 'system', content: prompt.system },
        { role: 'user', content: prompt.user }
      ],
      temperature: 0.3
    })
  });
  
  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.error?.message || 'OpenAI API request failed');
  }
  
  const data = await response.json();
  return data.choices[0].message.content.trim();
}

// Google Gemini API
async function callGemini(prompt, apiKey, model) {
  if (!apiKey) {
    throw new Error('Gemini API key not configured');
  }
  
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        contents: [{
          parts: [{
            text: `${prompt.system}\n\nText to correct:\n${prompt.user}`
          }]
        }],
        generationConfig: {
          temperature: 0.3
        }
      })
    }
  );
  
  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.error?.message || 'Gemini API request failed');
  }
  
  const data = await response.json();
  return data.candidates[0].content.parts[0].text.trim();
}

// Anthropic Claude API
async function callClaude(prompt, apiKey, model) {
  if (!apiKey) {
    throw new Error('Claude API key not configured');
  }
  
  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01'
    },
    body: JSON.stringify({
      model: model,
      max_tokens: 4096,
      system: prompt.system,
      messages: [
        { role: 'user', content: prompt.user }
      ],
      temperature: 0.3
    })
  });
  
  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.error?.message || 'Claude API request failed');
  }
  
  const data = await response.json();
  return data.content[0].text.trim();
}

// FastAPI endpoint (custom local endpoint)
async function callFastAPI(prompt, endpoint) {
  if (!endpoint) {
    throw new Error('FastAPI endpoint not configured');
  }
  
  // Auto-append /v1/chat/completions if it's a base URL
  let fullEndpoint = endpoint;
  if (!endpoint.includes('/v1/chat/completions') && 
      !endpoint.includes('/correct') && 
      !endpoint.includes('/api/')) {
    // Looks like a base URL, append the standard endpoint
    fullEndpoint = endpoint.replace(/\/$/, '') + '/v1/chat/completions';
    console.log('🪄 TypeMagic: Auto-appending /v1/chat/completions to endpoint');
  }
  
  console.log('🪄 TypeMagic: Calling FastAPI endpoint:', fullEndpoint);
  
  // For internal FastAPI endpoints, use simple format without model/key
  // OpenAI-compatible format (no API key needed for internal endpoints)
  const requestBody = {
    messages: [
      { role: "system", content: prompt.system },
      { role: "user", content: prompt.user }
    ],
    temperature: 0.3,
    max_tokens: 4096
  };
  
  console.log('🪄 TypeMagic: Request body:', JSON.stringify(requestBody).substring(0, 200));
  
  let response;
  try {
    response = await fetch(fullEndpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(requestBody)
    });
    
    console.log('🪄 TypeMagic: Response status:', response.status);
    console.log('🪄 TypeMagic: Response headers:', JSON.stringify([...response.headers.entries()]));
    
  } catch (fetchError) {
    // Network error, CORS, or fetch failed
    console.error('🪄 TypeMagic: Fetch failed:', fetchError);
    if (fetchError.message.includes('Failed to fetch')) {
      throw new Error(`Cannot reach endpoint ${fullEndpoint}. Check: 1) URL is correct, 2) Server is running, 3) CORS is enabled, 4) No firewall blocking`);
    }
    throw new Error(`Network error: ${fetchError.message}`);
  }
  
  // Check response status
  if (!response.ok) {
    let errorText;
    try {
      errorText = await response.text();
      console.error('🪄 TypeMagic: FastAPI error response:', errorText);
    } catch (e) {
      errorText = 'Could not read error response';
    }
    throw new Error(`API returned ${response.status}: ${errorText.substring(0, 200)}`);
  }
  
  // Try to parse response
  let data;
  try {
    const responseText = await response.text();
    console.log('🪄 TypeMagic: Response text (first 500 chars):', responseText.substring(0, 500));
    data = JSON.parse(responseText);
    console.log('🪄 TypeMagic: Response data keys:', Object.keys(data));
  } catch (parseError) {
    console.error('🪄 TypeMagic: Failed to parse JSON:', parseError);
    throw new Error('API response is not valid JSON. Check server logs.');
  }
  
  // Try multiple response formats
  const result = data.corrected_text || 
         data.text || 
         data.result || 
         data.choices?.[0]?.message?.content || // OpenAI format
         data.content ||
         data.response;
  
  if (!result) {
    console.error('🪄 TypeMagic: No recognized field in response. Full response:', JSON.stringify(data));
    throw new Error(`API response missing text field. Got keys: ${Object.keys(data).join(', ')}`);
  }
  
  return result;
}

// Ollama API (local)
async function callOllama(prompt, endpoint, model) {
  if (!endpoint) {
    throw new Error('Ollama endpoint not configured');
  }
  
  console.log('🪄 TypeMagic: Calling Ollama at', endpoint, 'with model', model);
  
  try {
    const response = await fetch(`${endpoint}/api/generate`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: model,
        prompt: `${prompt.system}\n\nText to correct:\n${prompt.user}`,
        stream: false,
        options: {
          temperature: 0.3
        }
      })
    });
    
    console.log('🪄 TypeMagic: Ollama response status:', response.status);
    
    if (!response.ok) {
      let errorMsg = `Ollama request failed with status ${response.status}`;
      try {
        const errorText = await response.text();
        console.error('🪄 TypeMagic: Ollama error response:', errorText);
        // Try to parse as JSON to get structured error
        try {
          const errorData = JSON.parse(errorText);
          errorMsg = errorData.error || errorData.message || errorMsg;
        } catch (e) {
          // If not JSON, use the text directly
          if (errorText) errorMsg += `: ${errorText}`;
        }
      } catch (e) {
        console.error('🪄 TypeMagic: Could not read error response:', e);
      }
      throw new Error(errorMsg);
    }
    
    const data = await response.json();
    console.log('🪄 TypeMagic: Ollama response received, length:', data.response?.length);
    return data.response.trim();
  } catch (error) {
    console.error('🪄 TypeMagic: Ollama error:', error);
    if (error.message.includes('fetch')) {
      throw new Error(`Cannot connect to Ollama at ${endpoint}. Make sure Ollama is running with 'ollama serve'`);
    }
    throw error;
  }
}
