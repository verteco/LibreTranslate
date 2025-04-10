#!/bin/bash
set -e

# Use PORT environment variable if provided by DigitalOcean
PORT="${PORT:-5000}"

# Create required directories
mkdir -p $HOME/.local/share/argos-translate/packages

# Start LibreTranslate with explicit host 0.0.0.0 to listen on all interfaces
exec ./venv/bin/libretranslate --host "0.0.0.0" --port "$PORT"
