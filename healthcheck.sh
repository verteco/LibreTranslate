#!/bin/bash

# Simple script to check if the application is running properly
# This will be executed regularly by the container to verify service health

PORT="${PORT:-5000}"
HEALTH_URL="http://localhost:${PORT}/languages"

echo "Checking LibreTranslate health at ${HEALTH_URL}"

# Try curl first
if command -v curl >/dev/null 2>&1; then
  response=$(curl -s -o /dev/null -w "%{http_code}" ${HEALTH_URL})
  if [ "$response" = "200" ]; then
    echo "Health check passed (curl): HTTP ${response}"
    exit 0
  else
    echo "Health check failed (curl): HTTP ${response}"
  fi
fi

# Try wget as backup
if command -v wget >/dev/null 2>&1; then
  if wget -q --spider ${HEALTH_URL}; then
    echo "Health check passed (wget)"
    exit 0
  else
    echo "Health check failed (wget)"
  fi
fi

# Check if process is running as last resort
if ps aux | grep -v grep | grep "libretranslate"; then
  echo "Process is running but web service is not responding"
else
  echo "Process is not running"
fi

exit 1
