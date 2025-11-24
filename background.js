// TypeMagic Background Service Worker
// Handles API calls to various AI providers

console.log('🪄 TypeMagic: Background service worker loaded');

// Listen for messages from content script
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  console.log('🪄 TypeMagic: Received message:', request.action);
  
  if (request.action === 'correctText') {
    handleTextCorrection(request.text)
      .then(correctedText => {
        console.log('🪄 TypeMagic: Correction successful');
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
async function handleTextCorrection(text) {
  console.log('🪄 TypeMagic: Starting text correction, text length:', text.length);
  
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
    systemPrompt: ''
  });
  
  console.log('🪄 TypeMagic: Using provider:', settings.provider);
  console.log('🪄 TypeMagic: Markdown enabled:', settings.useMarkdown);
  
  // Build the prompt
  const prompt = buildPrompt(text, settings.useMarkdown, settings.systemPrompt);
  
  // Call appropriate API based on provider
  switch (settings.provider) {
    case 'openai':
      return await callOpenAI(prompt, settings.openaiKey, settings.openaiModel);
    case 'gemini':
      return await callGemini(prompt, settings.geminiKey, settings.geminiModel);
    case 'claude':
      return await callClaude(prompt, settings.claudeKey, settings.claudeModel);
    case 'fastapi':
      return await callFastAPI(prompt, settings.fastApiEndpoint);
    case 'ollama':
      return await callOllama(prompt, settings.ollamaEndpoint, settings.ollamaModel);
    default:
      throw new Error('Invalid provider selected');
  }
}

// Build the correction prompt
function buildPrompt(text, useMarkdown, customSystemPrompt) {
  let systemPrompt = customSystemPrompt || 
    `You are a precise text correction assistant. Your job is to fix errors while preserving the user's unique voice, personality, and writing style.

Rules:
1. Fix spelling errors (e.g., "happnionnijn" → "happening")
2. Fix grammar errors (e.g., "Hell o" → "Hello")
3. Fix punctuation errors
4. PRESERVE the user's unique voice, tone, word choice, and personality
5. PRESERVE informal language, slang, and casual expressions if present
6. Do NOT rewrite sentences unless they are grammatically incorrect
7. Do NOT change vocabulary to "sound smarter" or more formal
8. Do NOT add new information or change what the user is saying
9. Do NOT homogenize the writing style - keep their individuality
${useMarkdown ? '10. Use Markdown formatting (bold, italic, headers, lists) to enhance readability' : '10. Return plain text without special formatting'}

CRITICAL: Make MINIMAL edits. Only fix actual errors. The goal is to correct mistakes while keeping the text sounding exactly like the user wrote it.

Return ONLY the corrected text. No explanations, no comments, no preamble.`;
  
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
  
  if (!response.ok) {
    throw new Error('Ollama request failed');
  }
  
  const data = await response.json();
  return data.response.trim();
}
