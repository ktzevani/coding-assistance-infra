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

i=1
while :; do
    repo_var="LLAMA_CPP_MODEL_HF_REPO_${i}"
    file_var="LLAMA_CPP_MODEL_HF_FILE_${i}"
    path_var="LLAMA_CPP_MODEL_PATH_${i}"

    repo="${!repo_var:-}"
    file="${!file_var:-}"
    path="${!path_var:-}"

    if [[ -z "${repo}" && -z "${file}" && -z "${path}" ]]; then
        break
    fi

    if [[ -z "${repo}" || -z "${file}" || -z "${path}" ]]; then
        echo "Incomplete llama.cpp model config at index ${i}" >&2
        echo "Expected all of:" >&2
        echo "  ${repo_var}" >&2
        echo "  ${file_var}" >&2
        echo "  ${path_var}" >&2
        exit 2
    fi

    download_gguf \
        "llama.cpp model ${i}" \
        "${repo}" \
        "${file}" \
        "${path}"

    i=$((i + 1))
done