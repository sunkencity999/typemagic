#!/bin/bash

# TypeMagic Ollama Installer for macOS

LOG_FILE="/tmp/typemagic_ollama_install.log"
OLLAMA_ORIGIN="chrome-extension://*"

echo "Starting TypeMagic Ollama Setup..." | tee -a "$LOG_FILE"

# 1. Detect Ollama
if ! command -v ollama &> /dev/null; then
    echo "Ollama not found. Installing..." | tee -a "$LOG_FILE"
    # Install Ollama
    curl -fsSL https://ollama.com/install.sh | sh
else
    echo "Ollama is already installed." | tee -a "$LOG_FILE"
fi

# 2. Set Environment Variable
echo "Configuring environment variables..." | tee -a "$LOG_FILE"
launchctl setenv OLLAMA_ORIGINS "$OLLAMA_ORIGIN"

# Persist for future shell sessions (Zsh/Bash)
if [ -f "$HOME/.zshrc" ]; then
    if ! grep -q "OLLAMA_ORIGINS" "$HOME/.zshrc"; then
        echo "export OLLAMA_ORIGINS=\"$OLLAMA_ORIGIN\"" >> "$HOME/.zshrc"
    fi
elif [ -f "$HOME/.bash_profile" ]; then
    if ! grep -q "OLLAMA_ORIGINS" "$HOME/.bash_profile"; then
        echo "export OLLAMA_ORIGINS=\"$OLLAMA_ORIGIN\"" >> "$HOME/.bash_profile"
    fi
fi

# restart ollama app if running to pick up new env vars?
# Ideally we kill it so we can restart it with new env vars or let the user know.
pkill ollama || true

# 3. Pull Model
echo "Pulling llama3.1:8b model (this may take a while)..." | tee -a "$LOG_FILE"
# We need ollama running to pull? Yes, usually `ollama serve` needs to be active or `ollama pull` starts a temporary runner.
# Actually `ollama pull` talks to the server. If the server isn't running, the CLI often starts it or fails.
# Let's ensure server is running.

# Check if serving
if ! curl -s http://127.0.0.1:11434/api/version > /dev/null; then
    echo "Starting Ollama server..." | tee -a "$LOG_FILE"
    ollama serve > /tmp/ollama_serve.log 2>&1 &
    PID=$!
    echo "Waiting for Ollama to start..." | tee -a "$LOG_FILE"
    sleep 5
else
    echo "Ollama server is already running." | tee -a "$LOG_FILE"
fi

echo "Downloading model..." | tee -a "$LOG_FILE"
ollama pull llama3.1:8b

echo "Setup Complete! You can close this window." | tee -a "$LOG_FILE"

