#!/usr/bin/env pwsh

function Test-ToolInstalled {
    param([string]$ToolName)

    if (-not (Get-Command $ToolName -ErrorAction SilentlyContinue)) {
        Write-Host "Error: $ToolName is not installed" -ForegroundColor Red
        exit 1
    }
}

Test-ToolInstalled "mkcert"

Write-Host "Running development environment setup"
Write-Host ""

Push-Location server
try {
    mix setup
    if ($LASTEXITCODE -ne 0) {
        throw "mix setup failed with exit code $LASTEXITCODE"
    }
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "Setup complete" -ForegroundColor Green
