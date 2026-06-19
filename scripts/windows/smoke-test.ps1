. (Join-Path $PSScriptRoot "common.ps1")
Import-DotEnv

function Test-GetEndpoint {
    param(
        [string] $Name,
        [string] $Uri
    )

    try {
        Invoke-WebRequest -Uri $Uri -Method Get -TimeoutSec 10 -UseBasicParsing | Out-Null
        Write-Host "OK   $Name"
    }
    catch {
        Write-Host "SKIP $Name ($Uri unavailable)"
    }
}

function Test-PostEndpoint {
    param(
        [string] $Name,
        [string] $Uri,
        [hashtable] $Body
    )

    try {
        $json = $Body | ConvertTo-Json -Depth 8 -Compress
        Invoke-WebRequest `
            -Uri $Uri `
            -Method Post `
            -ContentType "application/json" `
            -Body $json `
            -TimeoutSec 120 `
            -UseBasicParsing | Out-Null
        Write-Host "OK   $Name"
    }
    catch {
        Write-Host "SKIP $Name ($Uri request failed)"
    }
}

$ollamaPort = Get-EnvironmentValue -Name "OLLAMA_HOST_PORT" -Default "11434"
$llamaPort = Get-EnvironmentValue -Name "LLAMA_CPP_HOST_PORT" -Default "8080"
$embedPort = Get-EnvironmentValue -Name "LLAMA_CPP_EMBED_HOST_PORT" -Default "8081"
$qdrantPort = Get-EnvironmentValue -Name "QDRANT_HOST_PORT" -Default "6333"
$fastModel = Get-EnvironmentValue -Name "FAST_MODEL_OLLAMA" -Default "devstral:24b"
$ollamaEmbedModel = Get-EnvironmentValue -Name "EMBED_MODEL_OLLAMA" -Default "qwen3-embedding:0.6b"
$llamaChatModel = Get-EnvironmentValue -Name "LLAMA_CPP_CHAT_MODEL" -Default "qwen3-coder-30b-64k"
$embeddingModel = "local"

Test-GetEndpoint "Ollama native API" "http://127.0.0.1:$ollamaPort/api/tags"
Test-GetEndpoint "Ollama OpenAI API" "http://127.0.0.1:$ollamaPort/v1/models"
Test-GetEndpoint "llama.cpp OpenAI API" "http://127.0.0.1:$llamaPort/v1/models"
Test-GetEndpoint "llama.cpp embedding API" "http://127.0.0.1:$embedPort/v1/models"
Test-GetEndpoint "Qdrant API" "http://127.0.0.1:$qdrantPort/collections"

Test-PostEndpoint "Ollama embeddings" "http://127.0.0.1:$ollamaPort/api/embed" @{
    model = $ollamaEmbedModel
    input = "ping"
}
Test-PostEndpoint "Ollama chat" "http://127.0.0.1:$ollamaPort/v1/chat/completions" @{
    model = $fastModel
    messages = @(@{ role = "user"; content = "Reply OK" })
    max_tokens = 4
}
Test-PostEndpoint "llama.cpp chat" "http://127.0.0.1:$llamaPort/v1/chat/completions" @{
    model = $llamaChatModel
    messages = @(@{ role = "user"; content = "Reply OK" })
    max_tokens = 4
}
Test-PostEndpoint "llama.cpp embeddings" "http://127.0.0.1:$embedPort/v1/embeddings" @{
    model = $embeddingModel
    input = "ping"
}
