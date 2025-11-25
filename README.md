# TypeMagic

**AI-Powered Text Correction & Formatting for Chrome**

TypeMagic is a Chrome extension that automatically corrects spelling, grammar, and formatting in any text field across the web. Type freely without worrying about accuracy—let AI handle the corrections!

**Instant Corrections with Keyboard Shortcut**: Press Cmd+Shift+M (Mac) or Ctrl+Shift+M (Windows/Linux) to instantly correct selected text anywhere on the web.

## Features

- **Keyboard Shortcut**: Press Cmd+Shift+M (Mac) or Ctrl+Shift+M (Windows/Linux) for instant corrections
- **Tone Adjustment**: Choose between "Keep My Voice", "More Professional", or "More Casual"
- **Bulletize**: Convert paragraphs into clean, organized bullet points
- **Universal Compatibility**: Works on any webpage with text inputs (email, docs, social media, etc.)
- **Multiple AI Providers**: Support for OpenAI, Google Gemini, Anthropic Claude, Ollama, and custom FastAPI endpoints
- **Smart Formatting**: Optionally use Markdown to format your text with headers, lists, bold, italic, etc.
- **One-Click Correction**: Click the extension icon and press "Correct Text" to apply corrections
- **Google Docs Support**: Manual copy/paste workflow for Google Docs compatibility
- **Privacy-Focused**: Your API keys are stored locally; text is only sent to your chosen AI provider
- **Clean UI**: Beautiful popup interface with gradient design

## Installation

### From Source (Development)

1. **Clone or download this repository**
   ```bash
   git clone https://github.com/sunkencity999/typemagic.git
   cd typemagic
   ```

2. **Load the extension in Chrome**
   - Open Chrome and navigate to `chrome://extensions/`
   - Enable "Developer mode" (toggle in top-right corner)
   - Click "Load unpacked"
   - Select the `typemagic` folder
   - The extension should now appear in your extensions list!

## Setup & Configuration

### 1. Choose Your AI Provider

Click the TypeMagic icon in your Chrome toolbar, then click "Open Settings". Choose from:

#### **OpenAI** (Recommended for best quality)
- Get API key: [platform.openai.com/api-keys](https://platform.openai.com/api-keys)
- Recommended model: `gpt-4o-mini` (fast and cost-effective)
- Cost: ~$0.150 per 1M input tokens, $0.600 per 1M output tokens

#### **Google Gemini** (Great free tier)
- Get API key: [makersuite.google.com/app/apikey](https://makersuite.google.com/app/apikey)
- Recommended model: `gemini-pro`
- Cost: Free tier available with rate limits

#### **Anthropic Claude** (Excellent for nuanced corrections)
- Get API key: [console.anthropic.com](https://console.anthropic.com)
- Recommended model: `claude-3-5-sonnet-20241022`
- Cost: Varies by model

#### **Ollama** (100% Local & Free)
- Install Ollama: [ollama.ai](https://ollama.ai)
- Run: `ollama run llama3.2` (or any model of your choice)
- Default endpoint: `http://localhost:11434`
- Cost: **Free!** (runs on your machine)

#### **FastAPI** (Custom Endpoint)
- For self-hosted AI services
- Your endpoint should accept POST requests with:
  ```json
  {
    "system": "System prompt string",
    "text": "Text to correct"
  }
  ```
- And return:
  ```json
  {
    "corrected_text": "Corrected text here"
  }
  ```

### 2. Enable Markdown Formatting (Optional)

Toggle "Use Markdown Formatting" in settings to have the AI format your text with:
- **Headers** (`# H1`, `## H2`, etc.)
- **Bold** and *italic* text
- Lists (bullet points and numbered)
- And more Markdown features

### 3. Customize System Prompt (Advanced)

Create your own instructions for the AI by editing the "Custom System Prompt" field. This allows you to:
- Specify a particular writing style
- Add domain-specific vocabulary
- Control formatting preferences
- Adjust the level of corrections (e.g., "only fix spelling, keep grammar as-is")

## Usage

### Quick Keyboard Shortcut (Recommended)

1. **Click in any text field** or **select text** you want to correct
2. **Press Cmd+Shift+M** (Mac) or **Ctrl+Shift+M** (Windows/Linux)
3. Your text is instantly corrected in place!

This works everywhere: Gmail, Twitter, LinkedIn, Reddit, forums, text fields, and more.

### Using the Popup

#### For Google Docs

1. **Select and copy** the text you want to correct in Google Docs (Cmd/Ctrl+C)
2. **Click the TypeMagic extension icon** in your Chrome toolbar
3. **Paste the text** into the textarea at the top of the popup
4. **Select your desired tone** (Keep My Voice, More Professional, or More Casual)
5. **Click "Correct Text"** or **"Convert to Bullets"**
6. The corrected text is automatically copied to your clipboard
7. **Paste back** into Google Docs (Cmd/Ctrl+V)

#### For Other Sites (Text Fields, Email, Social Media)

1. **Click in any text field** (textarea, input, contentEditable element)
2. **Click the TypeMagic extension icon** in your toolbar
3. **Select your desired tone**
4. **Click "Correct Text"**
5. Your text is automatically corrected in place!

### Tips for Best Results

- Works best with at least a few sentences of text
- Great for quickly drafting emails, posts, and messages
- For partial corrections: Select only the text you want to fix before using the keyboard shortcut
- Review AI suggestions—they're usually excellent but not always perfect
- Google Docs requires the manual copy/paste workflow due to browser security restrictions
- Use the keyboard shortcut (Cmd+Shift+M) for the fastest workflow

## Supported Websites

TypeMagic works on virtually any website with text inputs:

- **Email**: Gmail, Outlook, Yahoo Mail
- **Documents**: Google Docs (via copy/paste), Notion, Confluence
- **Social Media**: Twitter/X, Facebook, LinkedIn, Reddit
- **Development**: GitHub, Stack Overflow, GitLab
- **Education**: Canvas, Blackboard, Moodle
- **Note Taking**: Evernote, OneNote, Bear
- **Any webpage** with textarea, input, or contentEditable fields

**Note:** Google Docs uses a proprietary editor that requires the copy/paste workflow described above.

## Privacy & Security

- **API keys stored locally**: Your credentials never leave your machine except to call the AI provider
- **No tracking**: TypeMagic doesn't collect any analytics or usage data
- **Minimal permissions**: Only requests necessary permissions for functionality
- **Your choice of provider**: Use local AI (Ollama) for complete privacy

## Troubleshooting

### Extension Not Working
- Ensure you're clicking in a text field before opening the popup
- For Google Docs: Use the textarea in the popup (copy/paste workflow)
- Refresh the page after installing or updating the extension

### API Errors
- Verify your API key is correct in settings
- Check your API provider's dashboard for rate limits or billing issues
- For Ollama: Ensure Ollama is running (`ollama serve`)
- Test connection using the "Test Connection" button in the popup

### Text Not Replacing
- Some rich text editors may not be fully supported
- Try selecting all text and pasting manually if auto-replacement fails
- Check browser console (F12) for error messages

### Performance Issues
- Use faster models like `gpt-4o-mini` or `llama3.2` for quicker responses
- Consider Ollama for completely local processing
- Large text blocks may take longer to process

## Development

### Project Structure
```
typemagic/
├── manifest.json          # Extension configuration
├── content.js            # Injects icons and handles UI
├── background.js         # API calls and text processing
├── popup.html/js         # Extension popup interface
├── options.html/js       # Settings page
├── styles.css            # Styling for injected elements
├── icons/                # Extension icons
│   ├── icon16.png
│   ├── icon48.png
│   ├── icon128.png
│   └── generate-icons.html
└── README.md             # This file
```

### Key Technologies
- **Chrome Extensions Manifest V3**: Modern extension architecture
- **Content Scripts**: DOM manipulation and UI injection
- **Service Workers**: Background processing and API calls
- **Chrome Storage API**: Persistent settings storage

### Adding New AI Providers

To add support for a new AI provider:

1. **Add provider option** in `options.html`:
   ```html
   <label class="provider-option" data-provider="newprovider">
     <input type="radio" name="provider" value="newprovider">
     <div>New Provider</div>
   </label>
   ```

2. **Add configuration section** in `options.html`:
   ```html
   <div class="provider-config" data-provider="newprovider">
     <!-- Add API key, model selection, etc. -->
   </div>
   ```

3. **Implement API call** in `background.js`:
   ```javascript
   async function callNewProvider(prompt, apiKey, model) {
     // Implement API call logic
     // Return corrected text string
   }
   ```

4. **Add to switch statement** in `handleTextCorrection()`:
   ```javascript
   case 'newprovider':
     return await callNewProvider(prompt, settings.newproviderKey, settings.newproviderModel);
   ```

## Future Enhancements

Potential features for future versions:

- [ ] Undo/redo functionality
- [ ] Side-by-side comparison view
- [ ] Custom correction rules/dictionary
- [ ] Language detection and translation
- [ ] Browser action badge showing correction count
- [ ] Firefox and Edge support

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

MIT License - feel free to use and modify as needed.

## Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Check existing issues for solutions
- Review the troubleshooting section above

---

## Developer

**Christopher Bradford**  
Email: admin@robotbirdservices.com  
Version: 1.1.0

---

*Type fast, correct faster with TypeMagic.*
