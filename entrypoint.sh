#!/bin/bash
set -e

# Debug information - this will be visible in the logs
echo "Starting LibreTranslate..."
echo "User: $(whoami)"
echo "Working directory: $(pwd)"
echo "Directory listing: $(ls -la)"

# Use PORT environment variable if provided by DigitalOcean
PORT="${PORT:-5000}"
echo "Using port: $PORT"

# Create required directories
mkdir -p $HOME/.local/share/argos-translate/packages
echo "Created model directory at $HOME/.local/share/argos-translate/packages"

# Core EU languages + English
CORE_LANGUAGES="en,de,fr,it,es"
echo "Loading only core languages: $CORE_LANGUAGES"

# Print environment variables
echo "Environment:"
echo "LT_HOST=${LT_HOST:-0.0.0.0}"
echo "LT_PORT=${PORT}"
echo "LT_SKIP_INSTALL_MODELS=${LT_SKIP_INSTALL_MODELS:-true}"
echo "LT_LOAD_ONLY=${LT_LOAD_ONLY:-$CORE_LANGUAGES}"

# Ensure the virtual environment is activated
source ./venv/bin/activate || echo "Failed to source venv"

# Check if libretranslate executable exists
if [ -f "./venv/bin/libretranslate" ]; then
  echo "Using ./venv/bin/libretranslate"
  # Start LibreTranslate with explicit host 0.0.0.0 to listen on all interfaces
  # and only load EU languages
  exec ./venv/bin/libretranslate --host "0.0.0.0" --port "$PORT" --load-only "${LT_LOAD_ONLY:-$CORE_LANGUAGES}"
elif [ -f "/app/venv/bin/libretranslate" ]; then
  echo "Using /app/venv/bin/libretranslate"
  # Alternative path
  exec /app/venv/bin/libretranslate --host "0.0.0.0" --port "$PORT" --load-only "${LT_LOAD_ONLY:-$CORE_LANGUAGES}"
else
  echo "ERROR: libretranslate executable not found!"
  echo "Files in ./venv/bin:"
  ls -la ./venv/bin || echo "Failed to list ./venv/bin"
  
  echo "Files in /app/venv/bin (if it exists):"
  ls -la /app/venv/bin 2>/dev/null || echo "/app/venv/bin not found"
  
  # Try python directly as fallback
  echo "Trying to run with python module..."
  exec python -m libretranslate --host "0.0.0.0" --port "$PORT" --load-only "${LT_LOAD_ONLY:-$CORE_LANGUAGES}"
fi
