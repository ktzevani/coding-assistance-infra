#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"
[[ -f .env ]] && set -a && source .env && set +a

check() {
    local name="$1"
    local url="$2"
    if curl -fsS --max-time 10 "${url}" >/dev/null; then
        printf 'OK   %s\n' "${name}"
    else
        printf 'SKIP %s (%s unavailable)\n' "${name}" "${url}"
    fi
}

post_check() {
    local name="$1"
    local url="$2"
    local body="$3"
    if curl -fsS --max-time 120 "${url}" \
        -H "Content-Type: application/json" \
        -d "${body}" >/dev/null; then
        printf 'OK   %s\n' "${name}"
    else
        printf 'SKIP %s (%s request failed)\n' "${name}" "${url}"
    fi
}

check "Ollama native API" "http://127.0.0.1:${OLLAMA_HOST_PORT:-11434}/api/tags"
check "Ollama OpenAI API" "http://127.0.0.1:${OLLAMA_HOST_PORT:-11434}/v1/models"
check "llama.cpp OpenAI API" "http://127.0.0.1:${LLAMA_CPP_HOST_PORT:-8080}/v1/models"
check "Qdrant API" "http://127.0.0.1:${QDRANT_HOST_PORT:-6333}/collections"
post_check \
    "Ollama embeddings" \
    "http://127.0.0.1:${OLLAMA_HOST_PORT:-11434}/api/embed" \
    "{\"model\":\"${EMBED_MODEL_OLLAMA:-qwen3-embedding:0.6b}\",\"input\":\"ping\"}"
post_check \
    "Ollama chat" \
    "http://127.0.0.1:${OLLAMA_HOST_PORT:-11434}/v1/chat/completions" \
    "{\"model\":\"${FAST_MODEL_OLLAMA:-devstral:24b}\",\"messages\":[{\"role\":\"user\",\"content\":\"Reply OK\"}],\"max_tokens\":4}"
post_check \
    "llama.cpp chat" \
    "http://127.0.0.1:${LLAMA_CPP_HOST_PORT:-8080}/v1/chat/completions" \
    '{"model":"local","messages":[{"role":"user","content":"Reply OK"}],"max_tokens":4}'
