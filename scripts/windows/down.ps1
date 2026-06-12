param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $ComposeArgument = @()
)

. (Join-Path $PSScriptRoot "common.ps1")

$statePath = Join-Path $script:RootDir ".local-ai-stack.ps.json"
if (Test-Path -LiteralPath $statePath) {
    $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    $arguments = [System.Collections.Generic.List[string]]::new()
    foreach ($file in @($state.composeFiles)) {
        $arguments.Add("-f")
        $arguments.Add([string] $file)
    }
    foreach ($profile in @($state.profiles)) {
        $arguments.Add("--profile")
        $arguments.Add([string] $profile)
    }
    $arguments.Add("down")
    foreach ($item in $ComposeArgument) {
        $arguments.Add($item)
    }
    Invoke-NativeCommand -FilePath "docker" -ArgumentList (@("compose") + $arguments.ToArray())
}
else {
    Invoke-Compose -ArgumentList (@("down") + $ComposeArgument)
}
