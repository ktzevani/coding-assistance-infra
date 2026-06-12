#!/usr/bin/env bash
set -euo pipefail

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

if command -v nvidia-smi >/dev/null 2>&1; then
    nvidia-smi --query-gpu=name,memory.total,memory.used --format=csv,noheader
fi

check "Ollama native API" "${OLLAMA_URL:-http://ollama:11434}/api/tags"
check "Ollama OpenAI API" "${OLLAMA_URL:-http://ollama:11434}/v1/models"
check "llama.cpp OpenAI API" "${LLAMA_CPP_URL:-http://llama-cpp:8080}/v1/models"
check "llama.cpp embedding API" "${LLAMA_CPP_EMBED_URL:-http://llama-cpp-embeddings:8080}/v1/models"
check "Qdrant API" "${QDRANT_URL:-http://qdrant:6333}/collections"
post_check \
    "Ollama embeddings" \
    "${OLLAMA_URL:-http://ollama:11434}/api/embed" \
    "{\"model\":\"${EMBED_MODEL_OLLAMA:-qwen3-embedding:0.6b}\",\"input\":\"ping\"}"
post_check \
    "Ollama chat" \
    "${OLLAMA_URL:-http://ollama:11434}/v1/chat/completions" \
    "{\"model\":\"${FAST_MODEL_OLLAMA:-devstral:24b}\",\"messages\":[{\"role\":\"user\",\"content\":\"Reply OK\"}],\"max_tokens\":4}"
post_check \
    "llama.cpp chat" \
    "${LLAMA_CPP_URL:-http://llama-cpp:8080}/v1/chat/completions" \
    '{"model":"local","messages":[{"role":"user","content":"Reply OK"}],"max_tokens":4}'
post_check \
    "llama.cpp embeddings" \
    "${LLAMA_CPP_EMBED_URL:-http://llama-cpp-embeddings:8080}/v1/embeddings" \
    "{\"model\":\"${EMBEDDING_MODEL:-local}\",\"input\":\"ping\"}"
