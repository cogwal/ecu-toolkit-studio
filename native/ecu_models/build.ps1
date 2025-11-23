<#
PowerShell build helper for Windows (MSVC or mingw depending on environment).
Usage:
  Open "x64 Native Tools Command Prompt for VS 2019/2022" and run:
    .\build.ps1
#>
param(
  [string]$BuildDir = "build"
)

if (-Not (Test-Path $BuildDir)) { New-Item -ItemType Directory -Path $BuildDir | Out-Null }
Push-Location $BuildDir

cmakeArgs = @(
  "-G", "Visual Studio 17 2022", # change as needed
  ".."
)

Write-Host "Configuring with CMake..."
cmake @cmakeArgs

Write-Host "Building..."
cmake --build . --config Release

Write-Host "Build complete. Built library should be copied to runner folders if present."
Pop-Location
