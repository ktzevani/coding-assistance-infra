#!/usr/bin/env bash
set -euo pipefail

backend="${1:-nvidia}"
case "${backend}" in
    nvidia)
        docker run --rm --gpus=all nvidia/cuda:12.8.1-base-ubuntu24.04 nvidia-smi
        ;;
    amd)
        docker run --rm --device=/dev/kfd --device=/dev/dri rocm/dev-ubuntu-24.04 rocminfo
        ;;
    cpu)
        echo "CPU mode does not expose a GPU."
        ;;
    *)
        echo "Usage: $0 [nvidia|amd|cpu]" >&2
        exit 2
        ;;
esac

