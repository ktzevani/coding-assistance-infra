. (Join-Path $PSScriptRoot "common.ps1")

$script:ComposeProfiles.Add("init")
Write-Host "GGUF models will be stored beneath MODEL_ROOT (default: $(Join-Path $script:RootDir 'models'))."
Invoke-Compose -ArgumentList @("run", "--rm", "--build", "model-init")
