#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

if [[ -f .local-ai-stack ]]; then
    # This file is generated only by up.sh and contains shell-escaped Compose arguments.
    read -r -a saved_args < .local-ai-stack
    docker compose "${saved_args[@]}" down "$@"
else
    compose down "$@"
fi

