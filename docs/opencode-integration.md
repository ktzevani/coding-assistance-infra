# OpenCode Integration

Install and pin OpenCode separately in each project dev container. Copy the
reviewed `config/clients/opencode.example.json` into the project and adapt it
there. The example intentionally remains client configuration rather than
infrastructure-service configuration.

Provider model keys must match the IDs returned by the serving endpoint. The
example uses the default Ollama `devstral:24b` model and exposes every named
section from `config/llama-cpp/models.ini` as a llama.cpp model choice. A
request's model ID selects the router profile and therefore its context,
output, cache, and sampling configuration. Update the provider keys whenever
the preset section names or `FAST_MODEL_OLLAMA` change.

The example also defines request timeouts, a small model, disabled sharing,
project-local LSP commands, compaction, MCP access, and tool permissions. These
are starting points, not facility-wide policy. In particular, ensure
`OPENCODE_MODEL` uses the configured `llama.cpp/<profile>` provider/model form
and that every declared LSP command is installed in the project dev container.

The example enables the central `rag-mcp` HTTP endpoint as a remote MCP server.
It disables OAuth because this loopback-only deployment does not provide OAuth.
Review or disable this MCP entry before using an untrusted project.

Use host-gateway URLs when the project is on another Docker network:

```text
http://host.docker.internal:11434/v1
http://host.docker.internal:8080/v1
http://host.docker.internal:8765/mcp
```

On Linux, add `host.docker.internal:host-gateway` to that dev container. If the
project container joins `${COMPOSE_PROJECT_NAME}-network`, use service DNS:

```text
http://ollama:11434/v1
http://llama-cpp:8080/v1
http://rag-mcp:8765/mcp
```

Keep conservative tool permissions and review project-local OpenCode and MCP
configuration before running an untrusted repository.
