# GPU Profiles

## NVIDIA

Install a compatible host driver and NVIDIA Container Toolkit, then verify:

```bash
./scripts/linux/inspect-gpu.sh nvidia
./scripts/linux/up.sh nvidia
```

On a Windows Docker Desktop/WSL 2 host:

```powershell
.\scripts\windows\inspect-gpu.ps1 nvidia
.\scripts\windows\up.ps1 nvidia
```

The override reserves `${GPU_COUNT}` NVIDIA devices (`all` by default) and
selects the official llama.cpp `server-cuda` image. Coding-profile offload is
controlled by `n-gpu-layers` and `override-tensor` in
`config/llama-cpp/models.ini`; embedding offload remains controlled by
`LLAMA_CPP_EMBED_N_GPU_LAYERS_NVIDIA`, which defaults to `-1`. The optional
GGUF embedding server uses the same CUDA image. On a 16 GB GPU, a small
embedding GGUF is practical, but it still competes with coding models for
VRAM.

## AMD / ROCm

The AMD override selects `ollama/ollama:rocm` and exposes `/dev/kfd` and
`/dev/dri`. llama.cpp ROCm is intentionally not supplied in v1. Host groups,
kernel drivers, and supported GPU generations vary; validate them before model
tuning. This device path is intended for native Linux hosts and generally is
not available through Docker Desktop on Windows.

## CPU

CPU mode is the default and is useful for static configuration, CI, embeddings,
and small models. Coding profiles must use CPU-appropriate `n-gpu-layers` and
tensor placement when the routing service is enabled without a GPU. The
embedding server uses `LLAMA_CPP_EMBED_N_GPU_LAYERS_CPU`, which defaults to
`0`. CPU mode is not the target profile for the supplied large coding-agent
profiles.

GPU exposure is a runtime concern. A GPU-capable image does not gain access to
host hardware unless Docker and Compose expose it.
