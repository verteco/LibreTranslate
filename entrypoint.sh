#!/bin/bash
set -e

# Use PORT environment variable if provided by DigitalOcean
PORT="${PORT:-5000}"

# Start LibreTranslate with the appropriate port
exec ./venv/bin/libretranslate --host "*" --port "$PORT"
