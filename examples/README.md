# TypeMagic Examples

## FastAPI Custom Endpoint

This example shows how to create your own custom API endpoint for TypeMagic.

### Quick Start

1. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

2. **Run the server**
   ```bash
   python fastapi_server.py
   ```

3. **Configure TypeMagic**
   - Open TypeMagic settings
   - Select "FastAPI" as provider
   - Enter endpoint: `http://localhost:8000/correct`
   - Save settings

4. **Test it!**
   - Go to any website with a text field
   - Type some text and click the TypeMagic icon
   - Your custom endpoint will process the text

### Customization

Edit `fastapi_server.py` to:
- Use your preferred AI provider (OpenAI, Anthropic, etc.)
- Implement custom correction logic
- Add authentication
- Add rate limiting
- Log corrections for analysis
- Connect to your own ML models

### Example Integrations

**Using OpenAI:**
```python
from openai import OpenAI
client = OpenAI(api_key="your-key")

response = client.chat.completions.create(
    model="gpt-4o-mini",
    messages=[
        {"role": "system", "content": request.system},
        {"role": "user", "content": request.text}
    ]
)
corrected = response.choices[0].message.content
```

**Using Anthropic Claude:**
```python
from anthropic import Anthropic
client = Anthropic(api_key="your-key")

message = client.messages.create(
    model="claude-3-5-sonnet-20241022",
    max_tokens=4096,
    system=request.system,
    messages=[{"role": "user", "content": request.text}]
)
corrected = message.content[0].text
```

**Using Local Model (e.g., Transformers):**
```python
from transformers import pipeline

corrector = pipeline("text2text-generation", model="your-model")
corrected = corrector(request.text)[0]['generated_text']
```

### Production Deployment

For production use:

1. **Add authentication**
   ```python
   from fastapi.security import HTTPBearer
   security = HTTPBearer()
   ```

2. **Add rate limiting**
   ```bash
   pip install slowapi
   ```

3. **Deploy to cloud**
   - Railway: https://railway.app
   - Render: https://render.com
   - AWS Lambda with Mangum
   - Google Cloud Run

4. **Use HTTPS**
   - Required for Chrome extensions
   - Get free SSL with Let's Encrypt

5. **Update CORS settings**
   ```python
   allow_origins=[
       "chrome-extension://your-extension-id"
   ]
   ```

### API Contract

Your endpoint must accept:
```json
POST /correct
{
  "system": "System instructions for the AI",
  "text": "Text to be corrected"
}
```

And return:
```json
{
  "corrected_text": "The corrected text"
}
```

### Troubleshooting

**CORS errors?**
- Make sure CORS middleware is configured correctly
- Check browser console for specific error

**Connection refused?**
- Verify server is running: `curl http://localhost:8000/health`
- Check firewall settings

**Slow responses?**
- Consider caching common corrections
- Use async processing for large texts
- Implement request queuing

### Next Steps

- Add support for multiple languages
- Implement correction history
- Add A/B testing for different AI models
- Build analytics dashboard
- Create user feedback system
