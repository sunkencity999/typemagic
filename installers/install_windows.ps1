# TypeMagic Ollama Installer for Windows
$ErrorActionPreference = "Stop"
$OllamaOrigin = "chrome-extension://*"

Write-Host "Starting TypeMagic Ollama Setup..."

# 1. Detect Ollama
if (Get-Command "ollama" -ErrorAction SilentlyContinue) {
    Write-Host "Ollama is already installed."
} else {
    Write-Host "Ollama not found. Installing via Winget..."
    winget install Ollama.Ollama
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to install Ollama. Please install manually from https://ollama.com"
    }
    # Refresh env vars
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# 2. Set Environment Variable
Write-Host "Configuring environment variables..."
[System.Environment]::SetEnvironmentVariable('OLLAMA_ORIGINS', $OllamaOrigin, 'User')
$env:OLLAMA_ORIGINS = $OllamaOrigin

# 3. Check Serving
Write-Host "Checking Ollama server status..."
try {
    $response = Invoke-WebRequest -Uri "http://127.0.0.1:11434/api/version" -UseBasicParsing -Method Head -ErrorAction Stop
    Write-Host "Ollama is running."
} catch {
    Write-Host "Starting Ollama serve..."
    Start-Process -FilePath "ollama" -ArgumentList "serve" -WindowStyle Hidden
    Start-Sleep -Seconds 5
}

# 4. Pull Model
Write-Host "Pulling llama3.1:8b model..."
ollama pull llama3.1:8b

Write-Host "Setup Complete! You can close this window."
Read-Host -Prompt "Press Enter to exit"
