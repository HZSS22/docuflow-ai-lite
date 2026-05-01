param(
    [switch]$SkipInstall
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "==================================================" -ForegroundColor DarkCyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor DarkCyan
}

function Test-CommandExists {
    param([string]$CommandName)
    return [bool](Get-Command $CommandName -ErrorAction SilentlyContinue)
}

function Configure-ExecutionPolicy {
    try {
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
        Write-Host "[OK] PowerShell execution policy configured" -ForegroundColor Green
    }
    catch {
        Write-Host "[NOTE] Could not change execution policy automatically" -ForegroundColor Yellow
    }
}

function Check-Node {
    if (Test-CommandExists "node" -and Test-CommandExists "npm") {
        Write-Host "[OK] Node.js and npm found" -ForegroundColor Green
        node -v
        npm -v
        return
    }

    Write-Host "Node.js or npm was not found." -ForegroundColor Red
    Write-Host "Please install Node.js LTS from:" -ForegroundColor Yellow
    Write-Host "https://nodejs.org/" -ForegroundColor Yellow
    throw "Node.js is required"
}

function Install-ClaudeCode {
    if ($SkipInstall) {
        Write-Host "[NOTE] Skipped Claude Code installation" -ForegroundColor Yellow
        return
    }

    Write-Host "Installing Claude Code..."
    npm install -g @anthropic-ai/claude-code
    Write-Host "[OK] Claude Code install command completed" -ForegroundColor Green
}

function Configure-DeepSeek {
    Write-Host ""
    Write-Host "Paste your DeepSeek API key." -ForegroundColor Cyan
    Write-Host "The key will be hidden while you type or paste it." -ForegroundColor DarkGray

    $apiKey = Read-Host "DeepSeek API Key" -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($apiKey)
    try {
        $plainApiKey = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }

    if ([string]::IsNullOrWhiteSpace($plainApiKey)) {
        throw "API Key cannot be empty"
    }

    Write-Host ""
    Write-Host "Choose a model:" -ForegroundColor Cyan
    Write-Host "1. deepseek-v4-pro"
    Write-Host "2. deepseek-v4-flash"
    $choice = Read-Host "Type 1 or 2. Press Enter to choose 1"

    $model = "deepseek-v4-pro"
    if ($choice -eq "2") {
        $model = "deepseek-v4-flash"
    }

    [Environment]::SetEnvironmentVariable("ANTHROPIC_AUTH_TOKEN", $plainApiKey, "User")
    [Environment]::SetEnvironmentVariable("ANTHROPIC_BASE_URL", "https://api.deepseek.com/anthropic", "User")
    [Environment]::SetEnvironmentVariable("ANTHROPIC_MODEL", $model, "User")

    $env:ANTHROPIC_AUTH_TOKEN = $plainApiKey
    $env:ANTHROPIC_BASE_URL = "https://api.deepseek.com/anthropic"
    $env:ANTHROPIC_MODEL = $model

    Write-Host "[OK] DeepSeek API configured" -ForegroundColor Green
    Write-Host "Model: $model"
}

function Create-Workspace {
    $workspace = Join-Path $HOME "DocuFlow-AI-Documents"
    New-Item -ItemType Directory -Path $workspace -Force | Out-Null

    $readme = Join-Path $workspace "README.txt"
    if (-not (Test-Path $readme)) {
        @"
Put local documents in this folder.

Open PowerShell and run:

cd "$workspace"
claude

Example prompt:
Please polish the documents in this folder. Make the writing smoother but do not change the original meaning.
"@ | Set-Content -Path $readme -Encoding ASCII
    }

    Write-Host "[OK] Workspace created: $workspace" -ForegroundColor Green
}

try {
    Write-Host ""
    Write-Host "DocuFlow AI Lite Setup" -ForegroundColor Green

    Write-Step "Step 1: Configure PowerShell policy"
    Configure-ExecutionPolicy

    Write-Step "Step 2: Check Node.js"
    Check-Node

    Write-Step "Step 3: Install Claude Code"
    Install-ClaudeCode

    Write-Step "Step 4: Configure DeepSeek API"
    Configure-DeepSeek

    Write-Step "Step 5: Create document workspace"
    Create-Workspace

    Write-Host ""
    Write-Host "Done. Close and reopen PowerShell, then run:" -ForegroundColor Green
    Write-Host "claude" -ForegroundColor Yellow
}
catch {
    Write-Host ""
    Write-Host "Setup failed:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

Write-Host ""
Read-Host "Press Enter to exit"
