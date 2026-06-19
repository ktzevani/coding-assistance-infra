# Troubleshooting

## Compose Does Not Parse

Run `docker compose version` and `make config`. This project expects Compose v2
with support for NVIDIA device reservations in the Compose deployment model.

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

Confirm `LLAMA_CPP_CONFIG_ROOT` contains `models.ini` and that
`LLAMA_CPP_MODELS_PRESET` is its mounted container path (normally
`/config/models.ini`). Every `model` path in the preset must be beneath
`/models`, with the corresponding host file beneath `MODEL_ROOT`.

If a request reports an unknown model, use a section name from `models.ini` as
the request's `model` value. If loading a profile runs out of memory, reduce its
context, batch size, GPU layers, tensor offload, or KV-cache precision in
`models.ini`. Router-wide boolean values accept `true`/`false`, `1`/`0`,
`yes`/`no`, or `on`/`off`.

`pull-models` requires a complete path/repository/file triplet at each numbered
index and stops at the first entirely empty index. Keep indices consecutive.

## RAG Indexing Fails

Confirm `RAG_COLLECTIONS_CONFIG` points to valid YAML whose collection name
matches `QDRANT_COLLECTION`. Missing collection entries use built-in patterns.

Confirm the project is beneath the host `RAG_WORKSPACE_ROOT`; the service mounts
that directory at its internal `WORKSPACE_ROOT` of `/workspaces`. Confirm the
selected embedding backend is available. For GGUF embeddings, confirm the model
path or Hugging Face repository, pooling mode, and `gguf-embeddings` feature.
Inspect:

```bash
docker compose -f docker-compose.yml -f docker-compose.rag.yml logs rag-mcp qdrant
```

If Qdrant reports a dimension or collection-identity mismatch after changing
embedding models, use a new `QDRANT_COLLECTION` or delete and rebuild the
existing collection.

## Project Container Cannot Reach Host

Add `host.docker.internal:host-gateway` to Linux dev containers, or join the
facility's user-defined network and use service names.

Docker Desktop project containers can normally use `host.docker.internal`
without an additional host-gateway declaration.
