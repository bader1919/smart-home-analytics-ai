#!/bin/bash
# wait-for-ollama.sh - Wait for Ollama service to be ready before starting the application

set -e

OLLAMA_URL="${OLLAMA_BASE_URL:-http://ollama:11434}"
MAX_ATTEMPTS=30
ATTEMPT=0

echo "Waiting for Ollama to be ready at $OLLAMA_URL..."

# Function to check if Ollama is responding
check_ollama() {
    curl -s -f "$OLLAMA_URL/api/tags" >/dev/null 2>&1
}

# Wait for Ollama to be ready
while ! check_ollama; do
    ATTEMPT=$((ATTEMPT + 1))
    
    if [ $ATTEMPT -ge $MAX_ATTEMPTS ]; then
        echo "? Ollama failed to become ready after $MAX_ATTEMPTS attempts"
        echo "? Attempting to start anyway..."
        break
    fi
    
    echo "? Attempt $ATTEMPT/$MAX_ATTEMPTS: Ollama not ready yet, waiting..."
    sleep 2
done

if check_ollama; then
    echo "? Ollama is ready! Starting Graphiti..."
else
    echo "??  Ollama might not be fully ready, but proceeding..."
fi

# Execute the main command
exec "$@"
