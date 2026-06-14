#!/usr/bin/env bash
set -euo pipefail

ollama_url="${OLLAMA_URL:-http://ollama:11434}"

download_gguf() {
    local label="$1"
    local repo="$2"
    local file="$3"
    local target="$4"
    local partial="${target}.part"
    local url
    local -a headers=()

    if [[ -z "${repo}" || -z "${file}" ]]; then
        echo "Skipping ${label}: no Hugging Face repo/file configured"
        return
    fi
    case "${target}" in
        /models/*) ;;
        *) echo "${label} target must be beneath /models: ${target}" >&2; exit 2 ;;
    esac
    if [[ "${target}" == *"/../"* || "${target}" == */.. ]]; then
        echo "${label} target must not contain parent traversal: ${target}" >&2
        exit 2
    fi
    if [[ -s "${target}" ]]; then
        echo "Skipping ${label}: already present at ${target}"
        return
    fi

    mkdir -p "$(dirname "${target}")"
    url="https://huggingface.co/${repo}/resolve/main/${file}?download=true"
    if [[ -n "${HF_TOKEN:-}" ]]; then
        headers=(-H "Authorization: Bearer ${HF_TOKEN}")
    fi
    echo "Downloading ${label}: ${repo}/${file} -> ${target}"
    curl -fL --retry 5 --retry-delay 2 --continue-at - "${headers[@]}" -o "${partial}" "${url}"
    mv "${partial}" "${target}"
    echo "Downloaded ${label} to ${target}"
}

for attempt in {1..60}; do
    if curl -fsS "${ollama_url}/api/tags" >/dev/null; then
        break
    fi
    [[ "${attempt}" == 60 ]] && { echo "Ollama did not become ready" >&2; exit 1; }
    sleep 2
done

for model in "${FAST_MODEL_OLLAMA:-devstral:24b}" "${EMBED_MODEL_OLLAMA:-qwen3-embedding:0.6b}"; do
    echo "Pulling Ollama model ${model}"
    curl -fsS "${ollama_url}/api/pull" -H "Content-Type: application/json" -d "{\"model\":\"${model}\",\"stream\":false}"
    echo
done

download_gguf "llama.cpp coding model" "${LLAMA_CPP_MODEL_HF_REPO:-}" "${LLAMA_CPP_MODEL_HF_FILE:-}" "${LLAMA_CPP_MODEL_PATH:-/models/Qwen3.6-35B-A3B-UD-Q3_K_S.gguf}"
download_gguf "llama.cpp embedding model" "${LLAMA_CPP_EMBED_MODEL_HF_REPO:-}" "${LLAMA_CPP_EMBED_MODEL_HF_FILE:-}" "${LLAMA_CPP_EMBED_MODEL_PATH:-/models/Qwen3-Embedding-0.6B-Q8_0.gguf}"

