# GGUF Embedding Models

Use a dedicated embedding GGUF with the `llama-cpp-embeddings` service. A
general chat or coding GGUF is not automatically a useful embedding model.
llama.cpp serves embedding models with `--embedding` and exposes the
OpenAI-compatible `/v1/embeddings` endpoint.

## Recommended Options

| Model | Why choose it | Pooling | Native dimension | Context |
|---|---|---:|---:|---:|
| `Qwen/Qwen3-Embedding-0.6B-GGUF:Q8_0` | Recommended default; multilingual and code retrieval | `last` | 1024 | 32k |
| `Qwen/Qwen3-Embedding-4B-GGUF:Q8_0` | Higher retrieval quality when memory permits | `last` | 2560 | 32k |
| `Qwen/Qwen3-Embedding-8B-GGUF:Q8_0` | Large high-quality profile for larger infrastructure | `last` | 4096 | 32k |
| `ggml-org/embeddinggemma-300M-GGUF:Q8_0` | Small, resource-efficient multilingual model | model default | 768 | 2048 |
| `nomic-ai/nomic-embed-text-v1.5-GGUF` | Small English-focused long-context option | `mean` | 768 | 8192 |
| BGE-M3 community GGUF conversion | Multilingual long-document retrieval | verify conversion | 1024 | 8192 |

Qwen's official GGUF model card explicitly documents llama.cpp server use with
`--embedding --pooling last`. Nomic requires task prefixes:

```dotenv
LLAMA_CPP_EMBED_POOLING=mean
EMBEDDING_DOCUMENT_PREFIX="search_document: "
EMBEDDING_QUERY_PREFIX="search_query: "
```

EmbeddingGemma supports smaller Matryoshka dimensions, but this facility uses
the full server-returned vector unless an upstream server option changes it.
BGE-M3 GGUF conversions are generally community-produced, so verify conversion
provenance and retrieval quality before relying on one.

For a 16 GB GPU shared with coding inference, begin with Qwen3 Embedding 0.6B
or EmbeddingGemma 300M. The Qwen 4B and 8B variants are valid GGUF options, but
their additional memory pressure can reduce the coding model size or context
that fits concurrently.

## Select A Model

Recommended default:

```dotenv
LLAMA_CPP_EMBED_MODEL_PATH=
LLAMA_CPP_EMBED_HF_REPO=Qwen/Qwen3-Embedding-0.6B-GGUF:Q8_0
LLAMA_CPP_EMBED_MODEL_ID=qwen3-embedding-0.6b-q8_0
LLAMA_CPP_EMBED_POOLING=last
EMBEDDING_DOCUMENT_PREFIX=
EMBEDDING_QUERY_PREFIX=
QDRANT_COLLECTION=project_memory_qwen3
```

Then start:

```bash
./scripts/linux/up.sh nvidia rag gguf-embeddings
```

When switching models, change `LLAMA_CPP_EMBED_MODEL_ID` and
`QDRANT_COLLECTION`, or delete and rebuild the old index. Vectors from
different models are not compatible even when their dimensions happen to
match.

## References

- [llama.cpp server embeddings API](https://github.com/ggml-org/llama.cpp/blob/master/tools/server/README.md#post-v1embeddings-openai-compatible-embeddings-api)
- [Qwen3 Embedding 0.6B official GGUF](https://huggingface.co/Qwen/Qwen3-Embedding-0.6B-GGUF)
- [EmbeddingGemma 300M GGUF from ggml-org](https://huggingface.co/ggml-org/embeddinggemma-300M-GGUF)
- [Nomic Embed Text v1.5 GGUF](https://huggingface.co/nomic-ai/nomic-embed-text-v1.5-GGUF)
- [BGE-M3 model card](https://huggingface.co/BAAI/bge-m3)
