#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

compose_profiles+=(--profile init)
compose run --rm model-init

