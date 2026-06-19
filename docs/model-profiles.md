# Model Profiles

## 16 GB VRAM Workstation

Start with:

| Profile | Backend | Initial target |
|---|---|---|
| `code-fast` | Ollama | Coding model, 8k context, one parallel request |
| `qwen3-coder-30b-32k` | llama.cpp | Lowest-memory supplied coding profile |
| `qwen3-coder-30b-64k` | llama.cpp | Default startup coding profile |
| `qwen3-coder-30b-128k` | llama.cpp | Extended-context coding profile |
| `qwen3-coder-30b-128k-planning` | llama.cpp | Extended-context, larger-output planning profile |
| `qwen3-coder-30b-256k` | llama.cpp | Maximum-context supplied profile; compressed KV cache |
| `qwen3-6-35b-a3b-64k` | llama.cpp | Alternate Qwen3.6 GGUF profile |
| `embeddings` | Ollama or llama.cpp | Lightweight embedding model or GGUF |

Do not assume a model tag or quantization fits merely from parameter count.
Weights, KV cache, runtime buffers, context, batch size, and concurrent
services all consume memory. Increase context or GPU layers one change at a
time while watching GPU and host memory.

## Larger GPUs

- 24 GB: larger contexts and less CPU offload become practical.
- 48 GB: stronger models can remain mostly GPU-resident; service contention
  still matters.
- 80+ GB or multi-GPU: consider assigning services to specific GPUs and adding
  separate llama.cpp profiles.

The coding router reads its active profiles from
`config/llama-cpp/models.ini`. Section names are client-visible model IDs.
Shared defaults belong in `[*]`; model-specific context, output, cache,
offload, batching, and sampling settings belong in each named section. Keep
router-wide lifecycle controls in `.env`.

See `docs/embedding-models.md` for GGUF embedding choices and required pooling
or query-prefix settings.
