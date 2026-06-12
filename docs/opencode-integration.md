# OpenCode Integration

Install and pin OpenCode separately in each project dev container. Copy the
ideas from `config/opencode/provider-snippet.example.jsonc` into the project's
reviewed OpenCode configuration.

Provider model keys must match the IDs returned by the serving endpoint. The
example uses the default Ollama `devstral:24b` model and llama.cpp's served
`local` model ID. Update the Ollama key and default model when
`FAST_MODEL_OLLAMA` changes.

Use host-gateway URLs when the project is on another Docker network:

```text
http://host.docker.internal:11434/v1
http://host.docker.internal:8080/v1
```

On Linux, add `host.docker.internal:host-gateway` to that dev container. If the
project container joins `${COMPOSE_PROJECT_NAME}-network`, use service DNS:

```text
http://ollama:11434/v1
http://llama-cpp:8080/v1
```

Keep conservative tool permissions and review project-local OpenCode and MCP
configuration before running an untrusted repository.

