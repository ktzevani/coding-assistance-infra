#!/usr/bin/env sh
set -eu

if [ -n "${LLAMA_CPP_EMBED_MODEL_PATH:-}" ]; then
  set -- --model "${LLAMA_CPP_EMBED_MODEL_PATH}"
elif [ -n "${LLAMA_CPP_EMBED_HF_REPO:-}" ]; then
  set -- --hf-repo "${LLAMA_CPP_EMBED_HF_REPO}"
else
  echo "Set LLAMA_CPP_EMBED_MODEL_PATH or LLAMA_CPP_EMBED_HF_REPO" >&2
  exit 2
fi

set -- "$@" \
  --host 0.0.0.0 \
  --port 8080 \
  --ctx-size "${LLAMA_CPP_EMBED_CTX_SIZE:-8192}" \
  --n-gpu-layers "${LLAMA_CPP_EMBED_N_GPU_LAYERS:-0}" \
  --threads "${LLAMA_CPP_EMBED_THREADS:-8}" \
  --batch-size "${LLAMA_CPP_EMBED_BATCH_SIZE:-2048}" \
  --ubatch-size "${LLAMA_CPP_EMBED_UBATCH_SIZE:-512}" \
  --parallel "${LLAMA_CPP_EMBED_PARALLEL:-1}" \
  --embedding

if [ -n "${LLAMA_CPP_EMBED_POOLING:-}" ]; then
  set -- "$@" --pooling "${LLAMA_CPP_EMBED_POOLING}"
fi

exec /app/llama-server "$@"
