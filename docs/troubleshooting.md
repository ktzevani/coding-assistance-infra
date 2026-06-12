# Troubleshooting

## Compose Does Not Parse

Run `docker compose version` and `make config`. This project expects Compose v2
with support for the `gpus` service key in the NVIDIA override.

## Ollama Is Unreachable

Run `docker compose ps` and `docker compose logs ollama`. Confirm the chosen
host port is free and that requests use `127.0.0.1` from the host or
`host.docker.internal` from another container.

## NVIDIA Is Not Visible

Run `./scripts/linux/inspect-gpu.sh nvidia`. A failure here is a host driver or NVIDIA
Container Toolkit problem, not a Dockerfile problem.

On Windows, run `.\scripts\windows\inspect-gpu.ps1 nvidia` and confirm Docker Desktop
is using the WSL 2 backend with a compatible NVIDIA Windows driver.

## llama.cpp Exits Immediately

Confirm `LLAMA_CPP_MODEL_PATH` is a container path beneath `/models` and its
host file exists beneath `MODEL_ROOT`. Reduce context, batch size, or GPU layers
after an out-of-memory failure.

## RAG Indexing Fails

Confirm the project is mounted beneath `WORKSPACE_ROOT` and the selected
embedding backend is available. For GGUF embeddings, confirm the model path or
Hugging Face repository, pooling mode, and `gguf-embeddings` feature. Inspect:

```bash
docker compose -f docker-compose.yml -f docker-compose.rag.yml logs rag-mcp qdrant
```

If Qdrant reports a dimension mismatch after changing embedding models, use a
new `QDRANT_COLLECTION` or rebuild the existing collection.

## Project Container Cannot Reach Host

Add `host.docker.internal:host-gateway` to Linux dev containers, or join the
facility's user-defined network and use service names.

Docker Desktop project containers can normally use `host.docker.internal`
without an additional host-gateway declaration.
