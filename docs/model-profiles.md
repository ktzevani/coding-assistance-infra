# Model Profiles

## 16 GB Workstation

Start with:

| Profile | Backend | Initial target |
|---|---|---|
| `code-fast` | Ollama | Coding model, 8k context, one parallel request |
| `code-strong` | llama.cpp | Manually selected GGUF, 16k context, tuned offload |
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

The current `.env` profile layer can later be replaced by a YAML loader without
changing service boundaries. Example declarations are under `config/`.

See `docs/embedding-models.md` for GGUF embedding choices and required pooling
or query-prefix settings.
