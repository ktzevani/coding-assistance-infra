#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"
[[ -f .env ]] && set -a && source .env && set +a

cat <<EOF
Host endpoints:
  Ollama:    http://127.0.0.1:${OLLAMA_HOST_PORT:-11434}/v1
  llama.cpp: http://127.0.0.1:${LLAMA_CPP_HOST_PORT:-8080}/v1
  GGUF embed: http://127.0.0.1:${LLAMA_CPP_EMBED_HOST_PORT:-8081}/v1
  Qdrant:    http://127.0.0.1:${QDRANT_HOST_PORT:-6333}
  RAG MCP:   http://127.0.0.1:${RAG_MCP_HOST_PORT:-8765}/mcp

From another dev container:
  Ollama:    http://host.docker.internal:${OLLAMA_HOST_PORT:-11434}/v1
  llama.cpp: http://host.docker.internal:${LLAMA_CPP_HOST_PORT:-8080}/v1
  GGUF embed: http://host.docker.internal:${LLAMA_CPP_EMBED_HOST_PORT:-8081}/v1

On ${COMPOSE_PROJECT_NAME:-local-ai-coding}-network:
  Ollama:    http://ollama:11434/v1
  llama.cpp: http://llama-cpp:8080/v1
  GGUF embed: http://llama-cpp-embeddings:8080/v1
EOF
