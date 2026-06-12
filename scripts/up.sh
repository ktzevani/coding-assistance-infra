#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

backend="${1:-${GPU_BACKEND:-cpu}}"
if [[ "${backend}" =~ ^(cpu|nvidia|amd)$ ]]; then
    shift || true
else
    backend="${GPU_BACKEND:-cpu}"
fi

add_backend "${backend}"
for feature in "$@"; do
    add_feature "${feature}"
done

printf '%q ' "${compose_files[@]}" "${compose_profiles[@]}" > .local-ai-stack
printf '\n' >> .local-ai-stack
compose up -d --build

