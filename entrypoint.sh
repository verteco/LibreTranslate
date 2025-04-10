#!/bin/bash
set -e

# Use PORT environment variable if provided by DigitalOcean
PORT="${PORT:-5000}"

# Create required directories
mkdir -p $HOME/.local/share/argos-translate/packages

# Start LibreTranslate with the appropriate port
exec ./venv/bin/libretranslate --host "*" --port "$PORT"
