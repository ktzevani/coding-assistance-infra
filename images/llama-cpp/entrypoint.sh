#!/usr/bin/env sh
set -eu

# Router-only llama.cpp server entrypoint.
#
# Required/expected:
#   LLAMA_CPP_MODELS_PRESET=/config/llama.cpp/models.ini
#
# Sensible defaults for a single-GPU local coding-agent setup:
#   - bind to 0.0.0.0 inside Docker
#   - expose port 8080
#   - allow only 1 loaded model/profile at a time
#   - autoload requested model profiles
#   - enable Flash Attention by default
#   - enable continuous batching by default
#
# Important:
#   Per-model parameters such as ctx-size, n-predict, cache-type-k/v,
#   n-gpu-layers, override-tensor, batch-size, ubatch-size, sampling, etc.
#   should remain in models.ini.

LLAMA_CPP_HOST="${LLAMA_CPP_HOST:-0.0.0.0}"
LLAMA_CPP_HOST_PORT="${LLAMA_CPP_HOST_PORT:-8080}"

LLAMA_CPP_MODELS_PRESET="${LLAMA_CPP_MODELS_PRESET:-/config/models.ini}"
LLAMA_CPP_MODELS_MAX="${LLAMA_CPP_MODELS_MAX:-1}"
LLAMA_CPP_FLASH_ATTN="${LLAMA_CPP_FLASH_ATTN:-on}"
LLAMA_CPP_CONT_BATCHING="${LLAMA_CPP_CONT_BATCHING:-true}"
LLAMA_CPP_MODELS_AUTOLOAD="${LLAMA_CPP_MODELS_AUTOLOAD:-true}"
LLAMA_CPP_METRICS="${LLAMA_CPP_METRICS:-false}"

if [ ! -f "${LLAMA_CPP_MODELS_PRESET}" ]; then
  echo "Missing models preset file: ${LLAMA_CPP_MODELS_PRESET}" >&2
  echo "Mount models.ini into the container or set LLAMA_CPP_MODELS_PRESET." >&2
  exit 2
fi

set -- \
  --host "${LLAMA_CPP_HOST}" \
  --port "${LLAMA_CPP_HOST_PORT}" \
  --models-preset "${LLAMA_CPP_MODELS_PRESET}" \
  --models-max "${LLAMA_CPP_MODELS_MAX}"

case "${LLAMA_CPP_MODELS_AUTOLOAD}" in
  true|1|yes|on) set -- "$@" --models-autoload ;;
  false|0|no|off) set -- "$@" --no-models-autoload ;;
  *) echo "Invalid LLAMA_CPP_MODELS_AUTOLOAD value: ${LLAMA_CPP_MODELS_AUTOLOAD}" >&2; exit 2 ;;
esac

case "${LLAMA_CPP_FLASH_ATTN}" in
  true|1|yes|on|auto) set -- "$@" --flash-attn "${LLAMA_CPP_FLASH_ATTN}" ;;
  false|0|no|off) set -- "$@" --flash-attn off ;;
  *) echo "Invalid LLAMA_CPP_FLASH_ATTN value: ${LLAMA_CPP_FLASH_ATTN}" >&2; exit 2 ;;
esac

case "${LLAMA_CPP_CONT_BATCHING}" in
  true|1|yes|on) set -- "$@" --cont-batching ;;
  false|0|no|off) set -- "$@" --no-cont-batching ;;
  *) echo "Invalid LLAMA_CPP_CONT_BATCHING value: ${LLAMA_CPP_CONT_BATCHING}" >&2; exit 2 ;;
esac

case "${LLAMA_CPP_METRICS}" in
  true|1|yes|on) set -- "$@" --metrics ;;
  false|0|no|off) ;;
  *) echo "Invalid LLAMA_CPP_METRICS value: ${LLAMA_CPP_METRICS}" >&2; exit 2 ;;
esac

# Optional API key support.
#
# Either:
#   LLAMA_CPP_API_KEY=secret
#
# Or:
#   LLAMA_CPP_API_KEY_FILE=/run/secrets/llama_cpp_api_key
#
if [ -n "${LLAMA_CPP_API_KEY:-}" ]; then
  set -- "$@" --api-key "${LLAMA_CPP_API_KEY}"
fi

if [ -n "${LLAMA_CPP_API_KEY_FILE:-}" ]; then
  if [ ! -f "${LLAMA_CPP_API_KEY_FILE}" ]; then
    echo "LLAMA_CPP_API_KEY_FILE does not exist: ${LLAMA_CPP_API_KEY_FILE}" >&2
    exit 2
  fi
  set -- "$@" --api-key-file "${LLAMA_CPP_API_KEY_FILE}"
fi

# Optional: pass raw extra llama-server args.
# Example:
#   LLAMA_CPP_EXTRA_ARGS="--verbose --log-prefix"
#
# Keep this last so it can override earlier choices if llama-server allows it.
if [ -n "${LLAMA_CPP_EXTRA_ARGS:-}" ]; then
  # shellcheck disable=SC2086
  set -- "$@" ${LLAMA_CPP_EXTRA_ARGS}
fi

exec /app/llama-server "$@"