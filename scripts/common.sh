#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

compose_files=(-f docker-compose.yml)
compose_profiles=()
rag_enabled=false
gguf_embeddings_enabled=false

add_backend() {
    case "$1" in
        cpu) compose_files+=(-f docker-compose.cpu.yml) ;;
        nvidia) compose_files+=(-f docker-compose.nvidia.yml) ;;
        amd) compose_files+=(-f docker-compose.amd.yml) ;;
        *) echo "Unknown backend: $1 (expected cpu, nvidia, or amd)" >&2; exit 2 ;;
    esac
}

add_feature() {
    case "$1" in
        llama) compose_profiles+=(--profile llama) ;;
        gguf-embeddings) gguf_embeddings_enabled=true; compose_profiles+=(--profile embeddings-gguf) ;;
        rag) rag_enabled=true; compose_files+=(-f docker-compose.rag.yml) ;;
        diagnostics) compose_profiles+=(--profile diagnostics) ;;
        dev) compose_files+=(-f docker-compose.dev.yml); compose_profiles+=(--profile dev) ;;
        "") ;;
        *) echo "Unknown feature: $1 (expected llama, gguf-embeddings, rag, diagnostics, or dev)" >&2; exit 2 ;;
    esac
}

finalize_features() {
    if [[ "${gguf_embeddings_enabled}" == true ]]; then
        if [[ "${rag_enabled}" != true ]]; then
            echo "The gguf-embeddings feature requires rag" >&2
            exit 2
        fi
        # Keep this last so its RAG backend selection wins regardless of CLI order.
        compose_files+=(-f docker-compose.embeddings-gguf.yml)
    fi
}

compose() {
    docker compose "${compose_files[@]}" "${compose_profiles[@]}" "$@"
}
