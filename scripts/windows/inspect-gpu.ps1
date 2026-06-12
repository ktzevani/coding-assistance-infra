param(
    [Parameter(Position = 0)]
    [ValidateSet("nvidia", "amd", "cpu")]
    [string] $Backend = "nvidia"
)

. (Join-Path $PSScriptRoot "common.ps1")

switch ($Backend) {
    "nvidia" {
        Invoke-NativeCommand -FilePath "docker" -ArgumentList @(
            "run", "--rm", "--gpus=all",
            "nvidia/cuda:12.8.1-base-ubuntu24.04", "nvidia-smi"
        )
    }
    "amd" {
        Write-Warning "The AMD container device mapping is intended for Linux hosts. Docker Desktop on Windows may not expose /dev/kfd or /dev/dri."
        Invoke-NativeCommand -FilePath "docker" -ArgumentList @(
            "run", "--rm", "--device=/dev/kfd", "--device=/dev/dri",
            "rocm/dev-ubuntu-24.04", "rocminfo"
        )
    }
    "cpu" {
        Write-Host "CPU mode does not expose a GPU."
    }
}
