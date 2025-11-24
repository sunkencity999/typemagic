"""
Example FastAPI server for TypeMagic
This demonstrates how to create a custom endpoint for text correction
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
import uvicorn

# Example using OpenAI (you could use any AI provider here)
# Uncomment and install: pip install openai
# from openai import OpenAI
# client = OpenAI(api_key="your-api-key-here")

app = FastAPI(title="TypeMagic Custom Endpoint")

# Enable CORS for Chrome extension
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your extension ID
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class CorrectionRequest(BaseModel):
    system: str
    text: str

class CorrectionResponse(BaseModel):
    corrected_text: str

@app.post("/correct", response_model=CorrectionResponse)
async def correct_text(request: CorrectionRequest):
    """
    Endpoint to correct and format text
    
    Args:
        request: Contains 'system' (instructions) and 'text' (text to correct)
    
    Returns:
        CorrectionResponse with corrected_text
    """
    
    try:
        # Example 1: Simple passthrough (for testing)
        # corrected = request.text.upper()
        
        # Example 2: Using OpenAI (uncomment to use)
        """
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": request.system},
                {"role": "user", "content": request.text}
            ],
            temperature=0.3
        )
        corrected = response.choices[0].message.content
        """
        
        # Example 3: Using local model or custom logic
        corrected = simple_correction(request.text)
        
        return CorrectionResponse(corrected_text=corrected)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def simple_correction(text: str) -> str:
    """
    Simple correction function - replace with your AI logic
    """
    # Basic example: just capitalize sentences
    import re
    
    # Split into sentences
    sentences = re.split(r'([.!?]+\s*)', text)
    
    # Capitalize first letter of each sentence
    result = []
    for i, part in enumerate(sentences):
        if i % 2 == 0 and part:  # Text part
            result.append(part[0].upper() + part[1:] if len(part) > 0 else part)
        else:  # Punctuation part
            result.append(part)
    
    return ''.join(result)

@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "status": "online",
        "service": "TypeMagic Custom Endpoint",
        "version": "1.0.0"
    }

@app.get("/health")
async def health():
    """Health check"""
    return {"status": "healthy"}

if __name__ == "__main__":
    print("🚀 Starting TypeMagic FastAPI server...")
    print("📍 Server will be available at: http://localhost:8000")
    print("📍 Correction endpoint: http://localhost:8000/correct")
    print("📝 Use this URL in TypeMagic extension settings")
    
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8000,
        log_level="info"
    )
