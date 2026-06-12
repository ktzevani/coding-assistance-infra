$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$script:RootDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $script:RootDir

$script:ComposeFiles = [System.Collections.Generic.List[string]]::new()
$script:ComposeProfiles = [System.Collections.Generic.List[string]]::new()
$script:ComposeFiles.Add("docker-compose.yml")
$script:RagEnabled = $false
$script:GgufEmbeddingsEnabled = $false

function Invoke-NativeCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string] $FilePath,

        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]] $ArgumentList
    )

    & $FilePath @ArgumentList
    if ($LASTEXITCODE -ne 0) {
        throw "$FilePath exited with code $LASTEXITCODE"
    }
}

function Add-Backend {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Backend
    )

    switch ($Backend.ToLowerInvariant()) {
        "cpu" { $script:ComposeFiles.Add("docker-compose.cpu.yml") }
        "nvidia" { $script:ComposeFiles.Add("docker-compose.nvidia.yml") }
        "amd" { $script:ComposeFiles.Add("docker-compose.amd.yml") }
        default { throw "Unknown backend: $Backend (expected cpu, nvidia, or amd)" }
    }
}

function Add-Feature {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Feature
    )

    switch ($Feature.ToLowerInvariant()) {
        "llama" { $script:ComposeProfiles.Add("llama") }
        "gguf-embeddings" {
            $script:GgufEmbeddingsEnabled = $true
            $script:ComposeProfiles.Add("embeddings-gguf")
        }
        "rag" {
            $script:RagEnabled = $true
            $script:ComposeFiles.Add("docker-compose.rag.yml")
        }
        "diagnostics" { $script:ComposeProfiles.Add("diagnostics") }
        "dev" {
            $script:ComposeFiles.Add("docker-compose.dev.yml")
            $script:ComposeProfiles.Add("dev")
        }
        "" { }
        default {
            throw "Unknown feature: $Feature (expected llama, gguf-embeddings, rag, diagnostics, or dev)"
        }
    }
}

function Complete-Features {
    if ($script:GgufEmbeddingsEnabled) {
        if (-not $script:RagEnabled) {
            throw "The gguf-embeddings feature requires rag"
        }

        # Keep this last so its RAG backend selection wins regardless of CLI order.
        $script:ComposeFiles.Add("docker-compose.embeddings-gguf.yml")
    }
}

function Get-ComposeArguments {
    $arguments = [System.Collections.Generic.List[string]]::new()
    foreach ($file in $script:ComposeFiles) {
        $arguments.Add("-f")
        $arguments.Add($file)
    }
    foreach ($profile in $script:ComposeProfiles) {
        $arguments.Add("--profile")
        $arguments.Add($profile)
    }
    return $arguments.ToArray()
}

function Invoke-Compose {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]] $ArgumentList
    )

    $composeArguments = @("compose") + @(Get-ComposeArguments) + $ArgumentList
    Invoke-NativeCommand -FilePath "docker" -ArgumentList $composeArguments
}

function Import-DotEnv {
    param(
        [string] $Path = (Join-Path $script:RootDir ".env")
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    foreach ($line in Get-Content -LiteralPath $Path) {
        $trimmed = $line.Trim()
        if (-not $trimmed -or $trimmed.StartsWith("#")) {
            continue
        }

        $separator = $trimmed.IndexOf("=")
        if ($separator -lt 1) {
            continue
        }

        $name = $trimmed.Substring(0, $separator).Trim()
        $value = $trimmed.Substring($separator + 1).Trim()
        if (
            $value.Length -ge 2 -and
            (($value.StartsWith('"') -and $value.EndsWith('"')) -or
             ($value.StartsWith("'") -and $value.EndsWith("'")))
        ) {
            $value = $value.Substring(1, $value.Length - 2)
        }
        [Environment]::SetEnvironmentVariable($name, $value, "Process")
    }
}

function Get-EnvironmentValue {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Name,

        [Parameter(Mandatory = $true)]
        [string] $Default
    )

    $value = [Environment]::GetEnvironmentVariable($Name, "Process")
    if ([string]::IsNullOrEmpty($value)) {
        return $Default
    }
    return $value
}
