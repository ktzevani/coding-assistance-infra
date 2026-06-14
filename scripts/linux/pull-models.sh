#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/linux/common.sh
source "$(dirname "$0")/common.sh"

compose_profiles+=(--profile init)
echo "GGUF models will be stored beneath MODEL_ROOT (default: ${ROOT_DIR}/models)."
compose run --rm --build model-init

