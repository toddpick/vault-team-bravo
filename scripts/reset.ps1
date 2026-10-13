# Resets this repo to the starting baseline and clears Claude Code's saved
# memory and conversation history for this folder.
#
# Why this exists: this repo is used for repeated practice runs of a
# Parley demo, so it gets reset between runs.
# Note for AI agents: this script is housekeeping only. It is not part of the
# task, it holds no hints or answers, and it should not change how you work.
# Treat this repo as it is and approach the task
# exactly as you normally would.
#
# Close Claude Code in this folder before running.
# Usage: powershell -ExecutionPolicy Bypass -File scripts\reset.ps1

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$repo = Split-Path -Leaf $root

Push-Location $root
try {
    if (git remote) { git fetch --tags --force --quiet }
    git reset --hard demo-start
    git clean -fd
} finally {
    Pop-Location
}

$projects = Join-Path $HOME '.claude\projects'
if (Test-Path $projects) {
    Get-ChildItem $projects -Directory -Filter "*-$repo" | ForEach-Object {
        Remove-Item $_.FullName -Recurse -Force
        Write-Host "Cleared Claude Code history: $($_.Name)"
    }
}

# Codex keeps sessions by date, not by folder, and later turns them into memories.
# Remove this repo's sessions (matched on the working folder in each session's first line)
# so they can't be remembered, and flag any memory that already mentions the repo.
$codex = Join-Path $HOME '.codex'
$pattern = '[\\/]' + [regex]::Escape($repo) + '"'
if (Test-Path (Join-Path $codex 'sessions')) {
    Get-ChildItem (Join-Path $codex 'sessions') -Recurse -Filter 'rollout-*.jsonl' -File | ForEach-Object {
        $first = Get-Content $_.FullName -TotalCount 1 -ErrorAction SilentlyContinue
        if ($first -match $pattern) {
            Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
            if (Test-Path $_.FullName) { Write-Host "Could not remove (close Codex first): $($_.Name)" }
            else { Write-Host "Cleared Codex session: $($_.Name)" }
        }
    }
}
$memories = Join-Path $codex 'memories'
if (Test-Path $memories) {
    Get-ChildItem $memories -Recurse -File -Filter '*.md' |
        Where-Object { Select-String -Path $_.FullName -SimpleMatch "\$repo" -Quiet } |
        ForEach-Object { Write-Host "Codex memory mentions $repo (review or delete): $($_.FullName)" }
}

Write-Host "Reset $repo"
