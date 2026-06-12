. (Join-Path $PSScriptRoot "common.ps1")
Import-DotEnv

$ollamaPort = Get-EnvironmentValue -Name "OLLAMA_HOST_PORT" -Default "11434"
$llamaPort = Get-EnvironmentValue -Name "LLAMA_CPP_HOST_PORT" -Default "8080"
$embedPort = Get-EnvironmentValue -Name "LLAMA_CPP_EMBED_HOST_PORT" -Default "8081"
$qdrantPort = Get-EnvironmentValue -Name "QDRANT_HOST_PORT" -Default "6333"
$ragPort = Get-EnvironmentValue -Name "RAG_MCP_HOST_PORT" -Default "8765"
$projectName = Get-EnvironmentValue -Name "COMPOSE_PROJECT_NAME" -Default "coding-assistance-infra"

@"
Host endpoints:
  Ollama:     http://127.0.0.1:$ollamaPort/v1
  llama.cpp:  http://127.0.0.1:$llamaPort/v1
  GGUF embed: http://127.0.0.1:$embedPort/v1
  Qdrant:     http://127.0.0.1:$qdrantPort
  RAG MCP:    http://127.0.0.1:$ragPort/mcp

From another dev container:
  Ollama:     http://host.docker.internal:$ollamaPort/v1
  llama.cpp:  http://host.docker.internal:$llamaPort/v1
  GGUF embed: http://host.docker.internal:$embedPort/v1

On $projectName-network:
  Ollama:     http://ollama:11434/v1
  llama.cpp:  http://llama-cpp:8080/v1
  GGUF embed: http://llama-cpp-embeddings:8080/v1
"@

