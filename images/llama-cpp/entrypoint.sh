#!/usr/bin/env sh
set -eu

: "${LLAMA_CPP_MODEL_PATH:?LLAMA_CPP_MODEL_PATH must point to a mounted GGUF model}"

set -- \
  --host 0.0.0.0 \
  --port 8080 \
  --model "${LLAMA_CPP_MODEL_PATH}" \
  --ctx-size "${LLAMA_CPP_CTX_SIZE:-16384}" \
  --n-gpu-layers "${LLAMA_CPP_N_GPU_LAYERS:-0}" \
  --threads "${LLAMA_CPP_THREADS:-12}" \
  --batch-size "${LLAMA_CPP_BATCH_SIZE:-512}" \
  --ubatch-size "${LLAMA_CPP_UBATCH_SIZE:-128}" \
  --cache-type-k "${LLAMA_CPP_CACHE_TYPE_K:-q8_0}" \
  --cache-type-v "${LLAMA_CPP_CACHE_TYPE_V:-q8_0}" \
  --parallel "${LLAMA_CPP_PARALLEL:-1}"

case "${LLAMA_CPP_CONT_BATCHING:-true}" in
  true|1|yes) set -- "$@" --cont-batching ;;
  false|0|no) set -- "$@" --no-cont-batching ;;
  *) echo "Invalid LLAMA_CPP_CONT_BATCHING value" >&2; exit 2 ;;
esac

exec /app/llama-server "$@"

