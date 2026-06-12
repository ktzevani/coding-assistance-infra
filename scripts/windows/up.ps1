param(
    [Parameter(Position = 0)]
    [string] $Backend,

    [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
    [string[]] $Feature = @()
)

. (Join-Path $PSScriptRoot "common.ps1")

$knownBackends = @("cpu", "nvidia", "amd")
if ([string]::IsNullOrEmpty($Backend)) {
    $Backend = Get-EnvironmentValue -Name "GPU_BACKEND" -Default "cpu"
}
elseif ($knownBackends -notcontains $Backend.ToLowerInvariant()) {
    $Feature = @($Backend) + $Feature
    $Backend = Get-EnvironmentValue -Name "GPU_BACKEND" -Default "cpu"
}

Add-Backend $Backend
foreach ($item in $Feature) {
    Add-Feature $item
}
Complete-Features

$state = @{
    composeFiles = @($script:ComposeFiles)
    profiles = @($script:ComposeProfiles)
}
$state | ConvertTo-Json | Set-Content -LiteralPath ".local-ai-stack.ps.json" -Encoding UTF8

Invoke-Compose -ArgumentList @("up", "-d", "--build")
