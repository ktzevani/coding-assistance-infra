#!/usr/bin/env bash
set -euo pipefail

ollama_url="${OLLAMA_URL:-http://ollama:11434}"

for attempt in {1..60}; do
    if curl -fsS "${ollama_url}/api/tags" >/dev/null; then
        break
    fi
    [[ "${attempt}" == 60 ]] && { echo "Ollama did not become ready" >&2; exit 1; }
    sleep 2
done

for model in "${FAST_MODEL_OLLAMA:-devstral:24b}" "${EMBED_MODEL_OLLAMA:-qwen3-embedding:0.6b}"; do
    echo "Pulling ${model}"
    curl -fsS "${ollama_url}/api/pull" \
        -H "Content-Type: application/json" \
        -d "{\"model\":\"${model}\",\"stream\":false}"
    echo
done

