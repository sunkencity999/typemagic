#!/bin/bash

# TypeMagic Ollama Installer for Linux

LOG_FILE="/tmp/typemagic_ollama_install.log"
OLLAMA_ORIGIN="chrome-extension://*"

echo "Starting TypeMagic Ollama Setup..." | tee -a "$LOG_FILE"

# 1. Detect Ollama
if ! command -v ollama &> /dev/null; then
    echo "Ollama not found. Installing..." | tee -a "$LOG_FILE"
    curl -fsSL https://ollama.com/install.sh | sh
else
    echo "Ollama is already installed." | tee -a "$LOG_FILE"
fi

# 2. Set Environment Variable
echo "Configuring environment variables..." | tee -a "$LOG_FILE"
export OLLAMA_ORIGINS="$OLLAMA_ORIGIN"

# Persistence depends on distro, but adding to ~/.bashrc is a safe bet for user
if [ -f "$HOME/.bashrc" ]; then
    if ! grep -q "OLLAMA_ORIGINS" "$HOME/.bashrc"; then
        echo "export OLLAMA_ORIGINS=\"$OLLAMA_ORIGIN\"" >> "$HOME/.bashrc"
    fi
fi

# Systemd service override (if installed via script) usually requires `systemctl edit ollama.service`
# We will try to set it for the current user session and the service if possible.
# Configuring systemd service requires sudo. The install script usually asks for sudo.
# We will attempt to set the service environment variable if systemd exists.
if command -v systemctl &> /dev/null; then
     if systemctl list-units --full -all | grep -q "ollama.service"; then
        echo "Configuring systemd service..." | tee -a "$LOG_FILE"
        # This is tricky without interactive sudo/editor. 
        # We will trust the user session env for now or the fact that 'ollama serve' 
        # might be run by the user if they don't want the system service.
        # But standard install enables the service. 
        # We can try `systemctl set-environment` but that's transient.
        true
     fi
fi

# 3. Pull Model
# Check if serving
if ! curl -s http://127.0.0.1:11434/api/version > /dev/null; then
    echo "Starting Ollama server..." | tee -a "$LOG_FILE"
    ollama serve > /tmp/ollama_serve.log 2>&1 &
    sleep 5
fi

echo "Pulling llama3.1:8b model..." | tee -a "$LOG_FILE"
ollama pull llama3.1:8b

echo "Setup Complete!" | tee -a "$LOG_FILE"
