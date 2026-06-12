# Windows Hosts

Use Docker Desktop with the WSL 2 backend and run the operator commands from
PowerShell. The PowerShell scripts mirror the Bash scripts:

| Bash | PowerShell |
|---|---|
| `./scripts/linux/up.sh` | `.\scripts\windows\up.ps1` |
| `./scripts/linux/down.sh` | `.\scripts\windows\down.ps1` |
| `./scripts/linux/pull-models.sh` | `.\scripts\windows\pull-models.ps1` |
| `./scripts/linux/smoke-test.sh` | `.\scripts\windows\smoke-test.ps1` |
| `./scripts/linux/print-endpoints.sh` | `.\scripts\windows\print-endpoints.ps1` |
| `./scripts/linux/inspect-gpu.sh` | `.\scripts\windows\inspect-gpu.ps1` |

## Quick Start

```powershell
Copy-Item .env.example .env
.\scripts\windows\up.ps1 cpu
.\scripts\windows\pull-models.ps1
.\scripts\windows\smoke-test.ps1
.\scripts\windows\print-endpoints.ps1
```

Feature syntax is identical:

```powershell
.\scripts\windows\up.ps1 nvidia llama
.\scripts\windows\up.ps1 nvidia rag
.\scripts\windows\up.ps1 nvidia rag gguf-embeddings
.\scripts\windows\down.ps1
```

The PowerShell wrapper records the selected Compose files and profiles in
`.local-ai-stack.ps.json`. Use `down.ps1` for a stack started by `up.ps1`.
The Bash wrappers maintain their own `.local-ai-stack` state file.

## PowerShell Compatibility

The scripts target Windows PowerShell 5.1 and PowerShell 7. If local execution
policy blocks repository scripts, run them for the current process with:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
```

Review scripts before changing execution policy.

## NVIDIA

Docker Desktop can expose supported NVIDIA GPUs to Linux containers through
WSL 2. Install a compatible Windows NVIDIA driver, enable Docker Desktop's WSL
2 backend, then verify:

```powershell
.\scripts\windows\inspect-gpu.ps1 nvidia
.\scripts\windows\up.ps1 nvidia
```

GPU availability is controlled by Docker Desktop, WSL 2, the Windows driver,
and Compose runtime configuration. It is not provided by a Dockerfile.

## AMD

The current AMD override exposes Linux `/dev/kfd` and `/dev/dri` devices.
That path is intended for native Linux hosts and generally is not available
through Docker Desktop on Windows. The PowerShell wrapper exposes the command
for interface parity, but warns before attempting it.

Use CPU mode on Windows when AMD ROCm device passthrough is unavailable.

## Paths And Storage

Compose resolves relative paths from the repository root. Keep `.env`,
`models/`, `data/`, and `workspaces/` beneath the repository unless absolute
Windows paths are tested carefully with Docker Desktop file sharing.

Models mounted into containers must still use Linux container paths in `.env`:

```dotenv
LLAMA_CPP_MODEL_PATH=/models/my-coding-model.gguf
LLAMA_CPP_EMBED_MODEL_PATH=/models/my-embedding-model.gguf
```

## Dev Containers

Project dev containers can reach host-published endpoints through
`host.docker.internal`, which Docker Desktop supplies automatically:

```text
http://host.docker.internal:11434/v1
http://host.docker.internal:8080/v1
http://host.docker.internal:8081/v1
http://host.docker.internal:8765/mcp
```
