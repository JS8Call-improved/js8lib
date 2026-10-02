# ==============================================================================
# Fixed PowerShell Script: Pack Qt 6.12.0 for GitHub Runners
# ==============================================================================
$ErrorActionPreference = "Stop"

# --- Configuration Paths ---
$QtInstallDir = "C:\Qt\6.12.0\llvm-mingw_64"   # Adjust if yours is different
$ZipOutputDir = "C:\Qt\Archive"
$ZipFileName  = "qt-6.12.0-windows-x64.zip"

# 1. Ensure Output Directory Exists
if (!(Test-Path $ZipOutputDir)) { 
    New-Item -ItemType Directory -Path $ZipOutputDir | Out-Null 
}

# 2. Inject Relative Path Override (Using single-line string to avoid parser bugs)
$QtConfPath = "$QtInstallDir\bin\qt.conf"
$QtConfContent = "[Paths]`nPrefix = .."

Write-Host "Writing configuration patch to: $QtConfPath" -ForegroundColor Cyan
Set-Content -Path $QtConfPath -Value $QtConfContent -Encoding UTF8

# 3. Generate the Archive
Write-Host "Archiving Qt installation folder (this may take a few minutes)..." -ForegroundColor Cyan
Compress-Archive -Path "$QtInstallDir\*" -DestinationPath "$ZipOutputDir\$ZipFileName" -Force

Write-Host "Archive successfully created at: $ZipOutputDir\$ZipFileName" -ForegroundColor Green
