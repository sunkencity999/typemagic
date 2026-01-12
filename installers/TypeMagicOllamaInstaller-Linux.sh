#!/bin/bash
set -e

# TypeMagic Ollama Installer for Linux
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
    # The official installer may prompt for sudo password
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

# Add to .bashrc (most common on Linux)
BASHRC="$HOME/.bashrc"
if [ ! -f "$BASHRC" ]; then
    touch "$BASHRC"
fi

if ! grep -q "OLLAMA_ORIGINS" "$BASHRC" 2>/dev/null; then
    echo "export OLLAMA_ORIGINS=\"$OLLAMA_ORIGIN\"" >> "$BASHRC"
    log "Added OLLAMA_ORIGINS to $BASHRC"
else
    log "OLLAMA_ORIGINS already configured in $BASHRC"
fi

# Also add to .profile for login shells
PROFILE="$HOME/.profile"
if [ -f "$PROFILE" ]; then
    if ! grep -q "OLLAMA_ORIGINS" "$PROFILE" 2>/dev/null; then
        echo "export OLLAMA_ORIGINS=\"$OLLAMA_ORIGIN\"" >> "$PROFILE"
        log "Added OLLAMA_ORIGINS to $PROFILE"
    fi
fi

# 3. Configure systemd service if it exists (requires sudo)
if command -v systemctl &> /dev/null; then
    if systemctl list-unit-files 2>/dev/null | grep -q "ollama.service"; then
        log "Configuring systemd service environment..."
        # Create override directory and file
        OVERRIDE_DIR="/etc/systemd/system/ollama.service.d"
        OVERRIDE_FILE="$OVERRIDE_DIR/environment.conf"
        
        if [ -w "/etc/systemd/system" ] || [ "$(id -u)" -eq 0 ]; then
            mkdir -p "$OVERRIDE_DIR" 2>/dev/null || sudo mkdir -p "$OVERRIDE_DIR"
            echo -e "[Service]\nEnvironment=\"OLLAMA_ORIGINS=$OLLAMA_ORIGIN\"" | sudo tee "$OVERRIDE_FILE" > /dev/null
            sudo systemctl daemon-reload
            sudo systemctl restart ollama.service 2>/dev/null || true
            log "Systemd service configured."
        else
            log "Note: Run with sudo to configure systemd service, or use user-mode Ollama."
        fi
    fi
fi

# 4. Stop any existing user-mode Ollama server (so we can restart with new env)
log "Stopping any existing Ollama server..."
pkill -9 ollama 2>/dev/null || true
sleep 2

# 5. Start Ollama server with OLLAMA_ORIGINS set
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

# 6. Pull Model
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
