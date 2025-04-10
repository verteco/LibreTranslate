#!/bin/bash
set -e

# Use PORT environment variable if provided by DigitalOcean
PORT="${PORT:-5000}"

# Start LibreTranslate with the appropriate port and skip model installation
exec ./venv/bin/libretranslate --host "*" --port "$PORT" --skip-model-check
