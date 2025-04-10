#!/bin/bash
set -e

# Use PORT environment variable if provided by DigitalOcean
PORT="${PORT:-5000}"

# Create data directory for language models if it doesn't exist
mkdir -p $HOME/.local/share/argos-translate/packages

# Start LibreTranslate with the appropriate port and skip model check flag
exec ./venv/bin/libretranslate --host "*" --port "$PORT" --skip-model-check
