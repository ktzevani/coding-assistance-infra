# Local AI Coding Facility — Context, Goals, and Implementation Brief

Date: 2026-06-12

## 1. Context

We want to build a Docker-deployable local AI facility for software-development agents. The primary client is OpenCode, installed independently inside per-project dev containers. The central facility should expose local model endpoints that those project containers can use through OpenAI-compatible APIs.

The intended separation is:

```text
Host / infrastructure level
  └── Local AI facility
        ├── Ollama service
        ├── llama.cpp server service
        ├── model storage/cache
        ├── optional embeddings service/model
        ├── optional vector DB / retrieval service
        └── optional monitoring / diagnostics

Per project level
  └── Dev container
        ├── source code
        ├── compiler/runtime/toolchain
        ├── project dependencies
        ├── OpenCode CLI
        ├── project opencode.json
        └── project AGENTS.md
```

OpenCode should remain project-local. Ollama / llama.cpp / embeddings / retrieval should be shared infrastructure.

The immediate local constraint is a single GPU with 16 GB VRAM, but the implementation must be parameterizable for larger GPUs and larger infra later.

## 2. Main design decision

Do **not** build one monolithic container that combines all responsibilities.

Preferred approach:

```text
central docker-compose.yml
  ├── ollama service
  ├── llama-cpp service
  ├── qdrant service, optional
  ├── rag-mcp service, optional
  ├── model-init service, optional
  └── smoke-test / diagnostics service, optional

images/
  ├── llama-cpp/
  ├── rag-mcp/
  ├── model-init/
  └── diagnostics/
```

Rationale:

- Ollama and llama.cpp have different lifecycle, tuning knobs, failure modes, and model-management behavior.
- Ollama is convenient for model pulling, simple local OpenAI-compatible use, and embeddings.
- llama.cpp is needed for precise quantization, context, KV-cache, and CPU/GPU offload tuning.
- GPU exposure is a runtime/Compose concern, not a Dockerfile concern. Dockerfiles can include CUDA/ROCm-capable binaries, but actual GPU access must be configured by Docker Compose and host GPU drivers/toolkits.
- Per-project OpenCode must stay decoupled from the shared inference facility.

## 3. Non-goals

The first implementation should **not** attempt to:

- Run OpenCode centrally as the default workflow.
- Replace per-project dev containers.
- Expose the inference facility publicly.
- Implement enterprise authentication.
- Build a sophisticated code graph on day one.
- Vectorize entire source trees blindly.
- Assume a 64k or 128k context window is practical on a 16 GB GPU.

## 4. Required repository layout

Implement this layout:

```text
.
├── docker-compose.yml
├── .env.example
├── README.md
├── Makefile                         # or taskfile, but Makefile is acceptable
├── config/
│   ├── ollama/
│   │   └── models.example.yaml       # optional model pull/alias declarations
│   ├── llama-cpp/
│   │   ├── server.env.example
│   │   └── models.example.yaml
│   ├── rag/
│   │   └── collections.example.yaml
│   └── opencode/
│       └── provider-snippet.example.jsonc
├── images/
│   ├── llama-cpp/
│   │   ├── Dockerfile
│   │   └── entrypoint.sh
│   ├── rag-mcp/
│   │   ├── Dockerfile
│   │   ├── pyproject.toml
│   │   └── src/
│   ├── model-init/
│   │   ├── Dockerfile
│   │   └── init-models.sh
│   └── diagnostics/
│       ├── Dockerfile
│       └── smoke-test.sh
├── scripts/
│   ├── up.sh
│   ├── down.sh
│   ├── pull-models.sh
│   ├── smoke-test.sh
│   ├── print-endpoints.sh
│   └── inspect-gpu.sh
└── docs/
    ├── architecture.md
    ├── model-profiles.md
    ├── opencode-integration.md
    ├── gpu-profiles.md
    └── troubleshooting.md
```

The root `docker-compose.yml` should be the primary deployment entrypoint.

## 5. Compose design

The Compose file should be quick to run on a normal developer machine, while supporting larger GPU systems later.

Use Compose profiles:

```text
Profiles:
  default / none     minimal CPU-safe services where possible
  ollama             Ollama service
  llama              llama.cpp service
  rag                Qdrant + rag-mcp services
  nvidia             NVIDIA GPU runtime settings
  amd                AMD/ROCm runtime settings where feasible
  diagnostics        smoke tests and inspection tools
```

However, Docker Compose profiles are not always ideal for runtime-specific GPU declarations. If Compose becomes awkward, prefer this practical structure:

```text
docker-compose.yml                  # base services and networks
docker-compose.nvidia.yml           # NVIDIA GPU overrides
docker-compose.amd.yml              # AMD/ROCm overrides
docker-compose.cpu.yml              # CPU-only overrides if needed
docker-compose.rag.yml              # optional retrieval stack
docker-compose.dev.yml              # local development overrides
```

Then expose wrapper scripts:

```bash
./scripts/up.sh nvidia
./scripts/up.sh cpu
./scripts/up.sh nvidia rag
./scripts/down.sh
./scripts/smoke-test.sh
```

The user-facing command should stay simple, even if the Compose internals use multiple files.

## 6. Environment parameterization

Create `.env.example` with at least:

```dotenv
# General
COMPOSE_PROJECT_NAME=local-ai-coding
DATA_ROOT=./data
MODEL_ROOT=./models
HF_HOME=./data/huggingface

# Endpoint ports
OLLAMA_HOST_PORT=11434
LLAMA_CPP_HOST_PORT=8080
QDRANT_HOST_PORT=6333
RAG_MCP_HOST_PORT=8765

# GPU / backend profile
GPU_BACKEND=nvidia          # nvidia | amd | cpu
GPU_COUNT=all               # all | 0 | 1 | specific device list if supported

# Ollama
OLLAMA_IMAGE=ollama/ollama:latest
OLLAMA_KEEP_ALIVE=24h
OLLAMA_NUM_PARALLEL=1
OLLAMA_FLASH_ATTENTION=1
OLLAMA_CONTEXT_LENGTH=8192

# Default model aliases / tags
FAST_MODEL_OLLAMA=devstral:24b
EMBED_MODEL_OLLAMA=qwen3-embedding:0.6b

# llama.cpp
LLAMA_CPP_IMAGE=local/llama-cpp-server:latest
LLAMA_CPP_MODEL_PATH=/models/qwen3.6-35b-a3b.gguf
LLAMA_CPP_CTX_SIZE=16384
LLAMA_CPP_N_GPU_LAYERS=-1
LLAMA_CPP_THREADS=12
LLAMA_CPP_BATCH_SIZE=512
LLAMA_CPP_UBATCH_SIZE=128
LLAMA_CPP_CACHE_TYPE_K=q8_0
LLAMA_CPP_CACHE_TYPE_V=q8_0
LLAMA_CPP_PARALLEL=1
LLAMA_CPP_CONT_BATCHING=true

# Retrieval
ENABLE_RAG=false
QDRANT_COLLECTION=project_memory
EMBEDDING_DIM=1024
RAG_TOP_K=8
RAG_MAX_CHUNK_TOKENS=600
RAG_MAX_CONTEXT_TOKENS=4000
```

Do not hardcode ports, model paths, or context sizes in the implementation.

## 7. Services

### 7.1 `ollama`

Purpose:

- Convenient local model management.
- Fast/default coding model endpoint.
- Embedding model endpoint.
- Simple OpenAI-compatible endpoint for OpenCode clients.

Use official image by default:

```yaml
image: ${OLLAMA_IMAGE:-ollama/ollama:latest}
```

Mount persistent storage:

```yaml
volumes:
  - ${DATA_ROOT:-./data}/ollama:/root/.ollama
```

Expose only locally by default:

```yaml
ports:
  - "127.0.0.1:${OLLAMA_HOST_PORT:-11434}:11434"
```

For containers on the same Compose network, clients should use:

```text
http://ollama:11434/v1
```

For external project devcontainers, document both possible access patterns:

```text
Linux / Docker host gateway:
  http://host.docker.internal:11434/v1

Same user-defined Docker network:
  http://ollama:11434/v1
```

For Linux, ensure `host.docker.internal` is supported via Compose `extra_hosts` where needed:

```yaml
extra_hosts:
  - "host.docker.internal:host-gateway"
```

### 7.2 `llama-cpp`

Purpose:

- Strong/offload coding profile.
- Explicit quantization and offload control.
- Larger models than the 16 GB GPU can fully contain.
- OpenAI-compatible API endpoint.

Use a custom image under `images/llama-cpp/` or a pinned upstream `ghcr.io/ggml-org/llama.cpp` server image if it satisfies the requirements.

The custom image should:

- Include `llama-server`.
- Support CUDA build for NVIDIA profile.
- Keep model files mounted from the host, not baked into the image.
- Use an entrypoint that maps env vars to `llama-server` flags.
- Expose port 8080 internally.

Entrypoint should support at least:

```bash
llama-server \
  --host 0.0.0.0 \
  --port 8080 \
  --model "${LLAMA_CPP_MODEL_PATH}" \
  --ctx-size "${LLAMA_CPP_CTX_SIZE}" \
  --n-gpu-layers "${LLAMA_CPP_N_GPU_LAYERS}" \
  --threads "${LLAMA_CPP_THREADS}" \
  --batch-size "${LLAMA_CPP_BATCH_SIZE}" \
  --ubatch-size "${LLAMA_CPP_UBATCH_SIZE}" \
  --cache-type-k "${LLAMA_CPP_CACHE_TYPE_K}" \
  --cache-type-v "${LLAMA_CPP_CACHE_TYPE_V}" \
  --parallel "${LLAMA_CPP_PARALLEL}"
```

Only add flags if supported by the pinned llama.cpp version. Avoid stale flags.

Expose only locally by default:

```yaml
ports:
  - "127.0.0.1:${LLAMA_CPP_HOST_PORT:-8080}:8080"
```

Mount models read-only:

```yaml
volumes:
  - ${MODEL_ROOT:-./models}:/models:ro
```

### 7.3 `qdrant`

Purpose:

- Optional vector storage for docs/project-memory retrieval.
- Not mandatory for the first smoke test.

Use official image:

```yaml
image: qdrant/qdrant:latest
```

Mount persistent storage:

```yaml
volumes:
  - ${DATA_ROOT:-./data}/qdrant:/qdrant/storage
```

Expose locally:

```yaml
ports:
  - "127.0.0.1:${QDRANT_HOST_PORT:-6333}:6333"
```

### 7.4 `rag-mcp`

Purpose:

- Optional MCP server that OpenCode can connect to.
- Provide narrow retrieval over project documentation, architecture notes, ADRs, README files, and curated memory.
- Do not blindly vectorize everything by default.

First implementation can be minimal:

- Python service.
- Uses Qdrant.
- Uses Ollama embeddings endpoint.
- Provides commands/tools:
  - `index_project_docs`
  - `search_project_memory`
  - `list_collections`
  - `delete_project_index`

Index these by default:

```text
README*
docs/**
adr/**
architecture/**
AGENTS.md
CHANGELOG*
CONTRIBUTING*
```

Exclude these by default:

```text
.git/**
.venv/**
node_modules/**
build/**
dist/**
target/**
.cache/**
__pycache__/**
*.png
*.jpg
*.jpeg
*.gif
*.pdf
*.zip
*.tar
*.gz
*.bin
*.onnx
*.pt
*.safetensors
```

Do not index source code recursively by default in v1. Source-code retrieval should first rely on OpenCode tools: grep, glob, read, bash, tests, compiler, and optional LSP.

### 7.5 `model-init`

Purpose:

- Optional one-shot container/script to pull Ollama models and validate model availability.
- Should be idempotent.

Example commands:

```bash
ollama pull "${FAST_MODEL_OLLAMA}"
ollama pull "${EMBED_MODEL_OLLAMA}"
```

If creating custom Ollama aliases with specific context parameters, place the generated Modelfiles under a persistent config directory and document the resulting model names.

### 7.6 `diagnostics`

Purpose:

- Verify GPU access.
- Verify endpoints.
- Verify OpenAI-compatible chat endpoint.
- Verify embeddings endpoint.
- Print memory usage and loaded models.

Smoke tests should check:

```text
nvidia-smi works in GPU service, if NVIDIA profile is active
ollama /api/tags responds
ollama /v1/models responds, if OpenAI-compatible path is enabled
llama.cpp /v1/models responds
llama.cpp /v1/chat/completions accepts a tiny request
qdrant /collections responds when RAG profile is active
```

## 8. GPU support

### 8.1 Important rule

Do not claim that a Dockerfile “uses the host GPU”. A Dockerfile can install GPU-capable software. The host GPU is exposed at runtime through Docker/Compose plus host driver/toolkit setup.

### 8.2 NVIDIA

For NVIDIA:

- Host must have NVIDIA driver installed.
- Host must have NVIDIA Container Toolkit installed/configured.
- Compose should request GPU access using current Compose-supported syntax.

Preferred Compose style:

```yaml
services:
  ollama:
    gpus: all

  llama-cpp:
    gpus: all
```

If device reservations are needed instead:

```yaml
deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          count: all
          capabilities: [gpu]
```

Validate with:

```bash
docker run --rm --gpus=all nvidia/cuda:12.6.0-base-ubuntu24.04 nvidia-smi
```

Use pinned CUDA base images where custom CUDA builds are required.

### 8.3 AMD / ROCm

AMD support is secondary but should be possible to add through overrides.

For Ollama, the official ROCm image path is:

```text
ollama/ollama:rocm
```

Typical device exposure:

```yaml
devices:
  - /dev/kfd
  - /dev/dri
```

For llama.cpp ROCm, implement later unless explicitly needed. Keep the architecture open for it but do not block NVIDIA/CPU implementation on ROCm.

### 8.4 CPU-only

CPU-only should remain available for:

- Testing Compose structure.
- Using small embedding models.
- Smoke testing endpoints.
- Machines without GPU.

CPU-only is not the target for high-quality coding-agent work, but it is useful for development and CI.

## 9. Model profiles

Model selection must be profile-based, not hardcoded.

### 9.1 Initial 16 GB VRAM profile

Use this as the default local workstation profile:

```text
Profile: code-fast
Backend: Ollama
Model: Devstral 24B / devstral:24b
Context target: 8192 first, then 16384 if stable
Purpose: daily OpenCode coding loop
```

```text
Profile: code-strong
Backend: llama.cpp
Model: Qwen3.6-35B-A3B GGUF or comparable strong coding GGUF
Quantization: selected manually based on fit
Context target: 16384 first, then 32768 if stable
Offload: maximize GPU layers without OOM
Purpose: difficult refactors, repo reasoning, code review, debugging
```

```text
Profile: embeddings
Backend: Ollama
Model: Qwen3 embedding 0.6B or equivalent lightweight embedding model
Purpose: docs/project-memory retrieval
```

### 9.2 Larger GPU profiles

The implementation should allow these future profiles without structural changes:

```text
24 GB VRAM:
  - larger context for Devstral/Qwen coding models
  - more practical Qwen3-Coder 30B / Qwen3.6 35B quantized runs
  - less CPU offload

48 GB VRAM:
  - larger coding models fully or mostly GPU-resident
  - 32k/64k context becomes more realistic
  - multiple services may still contend for VRAM

80+ GB VRAM / multi-GPU:
  - larger dense or MoE coding models
  - higher context
  - possible separate GPU assignment per service
  - possible multiple llama.cpp services with different model profiles
```

### 9.3 Required model-profile abstraction

Represent model profiles in config, not directly in Compose logic.

Example conceptual file:

```yaml
profiles:
  code-fast:
    backend: ollama
    model: devstral:24b
    base_url: http://ollama:11434/v1
    context: 8192

  code-strong:
    backend: llama-cpp
    model_path: /models/qwen3.6-35b-a3b.gguf
    base_url: http://llama-cpp:8080/v1
    context: 16384
    n_gpu_layers: -1
    cache_type_k: q8_0
    cache_type_v: q8_0

  embeddings:
    backend: ollama
    model: qwen3-embedding:0.6b
    base_url: http://ollama:11434/v1
```

The implementation may start with `.env`, but the design should be compatible with a future YAML profile loader.

## 10. OpenCode integration

OpenCode is not part of the central facility by default. Each project devcontainer installs/pins OpenCode separately.

Provide a reusable config snippet under:

```text
config/opencode/provider-snippet.example.jsonc
```

It should show how a project can connect to the shared local facility:

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "model": "ollama/code-fast",
  "provider": {
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Local Ollama",
      "options": {
        "baseURL": "http://host.docker.internal:11434/v1"
      },
      "models": {
        "code-fast": {
          "name": "Local fast coding model"
        }
      }
    },
    "llamacpp": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Local llama.cpp",
      "options": {
        "baseURL": "http://host.docker.internal:8080/v1"
      },
      "models": {
        "code-strong": {
          "name": "Local strong/offload coding model"
        }
      }
    }
  },
  "permission": {
    "bash": "ask",
    "edit": "ask",
    "webfetch": "ask",
    "websearch": "ask"
  }
}
```

Also provide a same-network variant:

```text
http://ollama:11434/v1
http://llama-cpp:8080/v1
```

Document when to use each variant.

## 11. Retrieval strategy

Retrieval is optional in v1 but the architecture should include it cleanly.

Correct retrieval order for coding agents:

```text
1. Deterministic project tools:
   grep, glob, read, bash, tests, compiler, linter, formatter, type checker

2. Project instructions:
   AGENTS.md, README, docs, known build/test commands

3. Optional LSP:
   useful for diagnostics and symbols, but project-specific and sometimes heavy

4. Narrow docs/project-memory RAG:
   useful for architecture notes, decisions, setup docs, debugging notes

5. Future code graph:
   Tree-sitter / symbol graph / dependency graph MCP
```

Do not implement broad source-code vectorization as the default. It can create misleading retrieval and unnecessary index churn.

First RAG implementation should focus on curated textual project memory:

```text
docs/
README*
AGENTS.md
ADR files
architecture notes
setup notes
troubleshooting notes
important issue/PR summaries
```

## 12. Security and permissions

Default posture:

- Bind service ports to `127.0.0.1` only.
- Do not expose to LAN unless explicitly configured.
- Do not bake secrets into images.
- Do not mount arbitrary host directories into LLM services except model/data directories.
- OpenCode permissions remain project-specific.
- Warn users that project-local OpenCode configs can define tools/MCP servers, so they should review configs before running untrusted repos.

For larger infra, add explicit access control before exposing endpoints remotely.

## 13. README requirements

The generated README should include:

1. What this project is.
2. Architecture diagram.
3. Prerequisites.
4. NVIDIA setup checklist.
5. AMD notes.
6. CPU-only mode.
7. Quick start.
8. Pull/init models.
9. Endpoint list.
10. OpenCode project integration.
11. Model-profile tuning.
12. RAG optional setup.
13. Troubleshooting.
14. Upgrade/pinning guidance.

Quick-start target UX:

```bash
cp .env.example .env
./scripts/up.sh nvidia
./scripts/pull-models.sh
./scripts/smoke-test.sh
./scripts/print-endpoints.sh
```

Expected output should tell the user:

```text
Ollama endpoint:    http://127.0.0.1:11434/v1
llama.cpp endpoint: http://127.0.0.1:8080/v1
Qdrant endpoint:    http://127.0.0.1:6333
```

## 14. Acceptance criteria

The Codex agent implementation is complete when:

### Compose and deployment

- `docker compose config` succeeds.
- `cp .env.example .env` works without manual edits for CPU-safe mode.
- NVIDIA mode can be started with one documented command.
- Services use persistent volumes/directories for model and vector data.
- Ports are bound to localhost by default.
- The central `docker-compose.yml` remains the main entrypoint.

### Ollama

- Ollama starts.
- Ollama data persists across restarts.
- A model can be pulled through `scripts/pull-models.sh`.
- The OpenAI-compatible endpoint is reachable from host and from another container.

### llama.cpp

- llama.cpp server image builds or a pinned upstream image is used.
- The server starts from env-configured model path and parameters.
- `/v1/models` responds.
- `/v1/chat/completions` accepts a tiny request.
- Context size, GPU layers, threads, and KV cache types are parameterized.

### RAG, if enabled

- Qdrant starts with persistent storage.
- rag-mcp can index a small docs directory.
- rag-mcp can retrieve top-k chunks.
- RAG is not required for base inference smoke tests.

### OpenCode integration

- Example OpenCode provider config is generated.
- It includes both Ollama and llama.cpp endpoints.
- It documents host-access and same-network access.
- It defaults to conservative permissions.

### Documentation

- README explains quick start and profiles.
- docs/model-profiles.md explains 16 GB VRAM vs larger GPU strategies.
- docs/gpu-profiles.md explains NVIDIA/AMD/CPU deployment differences.
- docs/opencode-integration.md explains per-project OpenCode installation/config.

## 15. Implementation sequence

Recommended order:

```text
1. Create repo layout and .env.example.
2. Implement base docker-compose.yml with ollama only.
3. Add scripts/up.sh, down.sh, print-endpoints.sh, smoke-test.sh.
4. Add NVIDIA override/profile and GPU inspection.
5. Add model-init/pull-models script.
6. Add llama.cpp service/image with parameterized entrypoint.
7. Add OpenCode provider snippet.
8. Add Qdrant service under optional RAG profile.
9. Add minimal rag-mcp service.
10. Add documentation and troubleshooting.
```

Do not start with RAG. First prove inference endpoints and OpenCode integration.

## 16. Reference sources to verify during implementation

The Codex agent should verify current docs before pinning syntax or image tags:

- Docker Compose GPU support: https://docs.docker.com/compose/how-tos/gpu-support/
- NVIDIA Container Toolkit install guide: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html
- Ollama Docker docs: https://docs.ollama.com/docker
- Ollama GPU docs: https://docs.ollama.com/gpu
- llama.cpp server docs: https://github.com/ggml-org/llama.cpp/blob/master/tools/server/README.md
- llama.cpp Docker docs: https://github.com/ggml-org/llama.cpp/blob/master/docs/docker.md
- OpenCode config docs: https://opencode.ai/docs/config/
- OpenCode provider docs: https://opencode.ai/docs/providers/
- OpenCode server docs: https://opencode.ai/docs/server/
- Qdrant installation docs: https://qdrant.tech/documentation/installation/

## 17. Key architectural reminder

The central facility provides local AI infrastructure. It does not own project logic.

Correct boundary:

```text
Shared local facility:
  inference, embeddings, optional retrieval, model storage, GPU usage

Per-project devcontainer:
  OpenCode, source code, tools, compilers, tests, permissions, AGENTS.md
```

This is the main principle the implementation must preserve.
