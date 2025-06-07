#!/bin/bash
echo "Waiting for Ollama to be ready..."

until curl -f http://ollama:11434/api/tags >/dev/null 2>&1; do
    echo "Ollama is not ready yet. Waiting..."
    sleep 5
done

echo "Ollama is ready! Starting Graphiti..."
exec "$@"
