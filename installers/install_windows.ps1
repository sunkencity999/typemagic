# TypeMagic Ollama Installer for Windows
# Runs non-interactively to set up Ollama for TypeMagic Chrome extension

$ErrorActionPreference = "Stop"
$OllamaOrigin = "chrome-extension://*"
$LogFile = "$env:TEMP\typemagic_ollama_install.log"
$MaxWait = 30

function Log($message) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp $message"
    Write-Host $logMessage
    Add-Content -Path $LogFile -Value $logMessage
}

Log "Starting TypeMagic Ollama Setup..."

# Set the environment variable for THIS session immediately
$env:OLLAMA_ORIGINS = $OllamaOrigin

# 1. Detect/Install Ollama
if (Get-Command "ollama" -ErrorAction SilentlyContinue) {
    Log "Ollama is already installed."
} else {
    Log "Ollama not found. Installing via Winget..."
    try {
        # Use --silent and --accept-* flags for non-interactive install
        winget install Ollama.Ollama --silent --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) {
            throw "Winget returned exit code $LASTEXITCODE"
        }
        Log "Ollama installed successfully."
        # Refresh PATH to find newly installed ollama
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    } catch {
        Log "ERROR: Failed to install Ollama. Please install manually from https://ollama.com"
        Log "Error details: $_"
        exit 1
    }
}

# 2. Set Environment Variable (persistent for user)
Log "Configuring environment variables..."
[System.Environment]::SetEnvironmentVariable('OLLAMA_ORIGINS', $OllamaOrigin, 'User')
Log "OLLAMA_ORIGINS set for current user."

# 3. Stop any existing Ollama process (so we can restart with new env)
Log "Stopping any existing Ollama server..."
Get-Process -Name "ollama" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# 4. Start Ollama server with OLLAMA_ORIGINS set
Log "Starting Ollama server with CORS enabled..."
$ollamaPath = (Get-Command "ollama" -ErrorAction SilentlyContinue).Source
if (-not $ollamaPath) {
    # Try common install location
    $ollamaPath = "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe"
    if (-not (Test-Path $ollamaPath)) {
        $ollamaPath = "ollama"
    }
}

# Start with environment variable set
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $ollamaPath
$psi.Arguments = "serve"
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true
$psi.EnvironmentVariables["OLLAMA_ORIGINS"] = $OllamaOrigin
[System.Diagnostics.Process]::Start($psi) | Out-Null

# Wait for server to be ready (with timeout)
Log "Waiting for Ollama server to start..."
$ready = $false
for ($i = 1; $i -le $MaxWait; $i++) {
    try {
        $response = Invoke-WebRequest -Uri "http://127.0.0.1:11434/api/version" -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
        Log "Ollama server is ready."
        $ready = $true
        break
    } catch {
        Start-Sleep -Seconds 1
    }
}

if (-not $ready) {
    Log "ERROR: Ollama server failed to start within ${MaxWait}s."
    exit 1
}

# 5. Pull Model
Log "Pulling llama3.1:8b model (this may take several minutes)..."
try {
    ollama pull llama3.1:8b
    if ($LASTEXITCODE -ne 0) {
        throw "ollama pull returned exit code $LASTEXITCODE"
    }
    Log "Model downloaded successfully."
} catch {
    Log "ERROR: Failed to download model. Please run 'ollama pull llama3.1:8b' manually."
    Log "Error details: $_"
    exit 1
}

Log "============================================"
Log "Setup Complete!"
Log "Ollama is running with CORS enabled for Chrome extensions."
Log "You can now use TypeMagic with Ollama as your AI provider."
Log "============================================"

exit 0
