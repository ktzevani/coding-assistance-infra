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

The override requests GPUs with Compose `gpus: all` and selects the official
llama.cpp `server-cuda` image. Both llama.cpp services default to `-1` GPU
layers in this profile for full offload. Set `LLAMA_CPP_N_GPU_LAYERS` and
`LLAMA_CPP_EMBED_N_GPU_LAYERS` in `.env` only when explicit limits are needed.
The optional GGUF embedding server uses the same CUDA image. On a 16 GB GPU,
a small embedding GGUF is practical, but it still competes with coding models
for VRAM.

## AMD / ROCm

The AMD override selects `ollama/ollama:rocm` and exposes `/dev/kfd` and
`/dev/dri`. llama.cpp ROCm is intentionally not supplied in v1. Host groups,
kernel drivers, and supported GPU generations vary; validate them before model
tuning. This device path is intended for native Linux hosts and generally is
not available through Docker Desktop on Windows.

## CPU

CPU mode is the default and is useful for Compose validation, CI, embeddings,
and small models. It sets llama.cpp GPU layers to zero. It is not the target
profile for large coding-agent models.

GPU exposure is a runtime concern. A GPU-capable image does not gain access to
host hardware unless Docker and Compose expose it.
