#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

compose_files=(-f docker-compose.yml)
compose_profiles=()

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
        rag) compose_files+=(-f docker-compose.rag.yml) ;;
        diagnostics) compose_profiles+=(--profile diagnostics) ;;
        dev) compose_files+=(-f docker-compose.dev.yml); compose_profiles+=(--profile dev) ;;
        "") ;;
        *) echo "Unknown feature: $1 (expected llama, rag, diagnostics, or dev)" >&2; exit 2 ;;
    esac
}

compose() {
    docker compose "${compose_files[@]}" "${compose_profiles[@]}" "$@"
}

