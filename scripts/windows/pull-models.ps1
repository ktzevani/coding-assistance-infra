. (Join-Path $PSScriptRoot "common.ps1")

$script:ComposeProfiles.Add("init")
Invoke-Compose -ArgumentList @("run", "--rm", "model-init")
