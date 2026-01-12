#!/bin/bash
set -e

# TypeMagic Ollama Installer for macOS
# Runs non-interactively to set up Ollama for TypeMagic Chrome extension

LOG_FILE="/tmp/typemagic_ollama_install.log"
OLLAMA_ORIGIN="chrome-extension://*"
MAX_WAIT=30

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOG_FILE"
}

log "Starting TypeMagic Ollama Setup..."

# Set the environment variable for THIS session immediately
export OLLAMA_ORIGINS="$OLLAMA_ORIGIN"

# 1. Detect/Install Ollama
if ! command -v ollama &> /dev/null; then
    log "Ollama not found. Installing..."
    # Download and run installer (may require password prompt on first run)
    if curl -fsSL https://ollama.com/install.sh | sh; then
        log "Ollama installed successfully."
    else
        log "ERROR: Failed to install Ollama. Please install manually from https://ollama.com"
        exit 1
    fi
else
    log "Ollama is already installed."
fi

# 2. Persist Environment Variable for future shell sessions
log "Configuring environment variables..."

# Create .zshrc if it doesn't exist (macOS default shell)
ZSHRC="$HOME/.zshrc"
if [ ! -f "$ZSHRC" ]; then
    touch "$ZSHRC"
fi

if ! grep -q "OLLAMA_ORIGINS" "$ZSHRC" 2>/dev/null; then
    echo "export OLLAMA_ORIGINS=\"$OLLAMA_ORIGIN\"" >> "$ZSHRC"
    log "Added OLLAMA_ORIGINS to $ZSHRC"
else
    log "OLLAMA_ORIGINS already configured in $ZSHRC"
fi

# Also add to .bash_profile if it exists
if [ -f "$HOME/.bash_profile" ]; then
    if ! grep -q "OLLAMA_ORIGINS" "$HOME/.bash_profile" 2>/dev/null; then
        echo "export OLLAMA_ORIGINS=\"$OLLAMA_ORIGIN\"" >> "$HOME/.bash_profile"
        log "Added OLLAMA_ORIGINS to .bash_profile"
    fi
fi

# 3. Stop any existing Ollama server (so we can restart with new env)
log "Stopping any existing Ollama server..."
pkill -9 ollama 2>/dev/null || true
sleep 2

# 4. Start Ollama server with OLLAMA_ORIGINS set
log "Starting Ollama server with CORS enabled..."
OLLAMA_ORIGINS="$OLLAMA_ORIGIN" nohup ollama serve > /tmp/ollama_serve.log 2>&1 &
SERVER_PID=$!

# Wait for server to be ready (with timeout)
log "Waiting for Ollama server to start..."
for i in $(seq 1 $MAX_WAIT); do
    if curl -s http://127.0.0.1:11434/api/version > /dev/null 2>&1; then
        log "Ollama server is ready."
        break
    fi
    if [ $i -eq $MAX_WAIT ]; then
        log "ERROR: Ollama server failed to start within ${MAX_WAIT}s. Check /tmp/ollama_serve.log"
        exit 1
    fi
    sleep 1
done

# 5. Pull Model
log "Pulling llama3.1:8b model (this may take several minutes)..."
if ollama pull llama3.1:8b; then
    log "Model downloaded successfully."
else
    log "ERROR: Failed to download model. Please run 'ollama pull llama3.1:8b' manually."
    exit 1
fi

log "============================================"
log "Setup Complete!"
log "Ollama is running with CORS enabled for Chrome extensions."
log "You can now use TypeMagic with Ollama as your AI provider."
log "============================================"

exit 0

