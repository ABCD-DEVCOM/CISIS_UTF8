# find_compilers.ps1 - shows which compilers usable for CISIS exist on this Windows machine.
# Usage (PowerShell):  powershell -ExecutionPolicy Bypass -File .\find_compilers.ps1
$ErrorActionPreference = 'SilentlyContinue'
Write-Host "== Borland C++ 5.5 (the compiler of the official .exe files) =="
$bcc = @('C:\Borland\BCC55\Bin\bcc32.exe') + (Get-ChildItem 'C:\' -Directory -Filter 'Borland*' | ForEach-Object { Join-Path $_.FullName 'BCC55\Bin\bcc32.exe' })
$found = $bcc | Where-Object { Test-Path $_ } | Select-Object -Unique
if ($found) { $found | ForEach-Object { "  FOUND: $_" } } else { "  not found" }
(Get-Command bcc32).Source | ForEach-Object { "  on PATH: $_" }

Write-Host "`n== GCC / MinGW / MSYS2 / Dev-C++ / CodeBlocks =="
$cand = @('C:\msys64\mingw64\bin\gcc.exe','C:\msys64\mingw32\bin\gcc.exe','C:\msys64\ucrt64\bin\gcc.exe',
          'C:\Dev-Cpp\bin\gcc.exe','C:\Dev-Cpp\MinGW64\bin\gcc.exe','C:\MinGW\bin\gcc.exe',
          'C:\Program Files (x86)\CodeBlocks\MinGW\bin\gcc.exe','C:\Program Files\CodeBlocks\MinGW\bin\gcc.exe',
          'C:\Win-Builds\bin\gcc.exe')
$cand | Where-Object { Test-Path $_ } | ForEach-Object { "  $_  ->  " + (& $_ --version | Select-Object -First 1) }
Get-Command gcc | ForEach-Object { "  on PATH: $($_.Source)  ->  " + (& $_.Source --version | Select-Object -First 1) }

Write-Host "`n== Microsoft Visual Studio (cl.exe) =="
$vsw = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vsw) { & $vsw -latest -products * -property installationPath | ForEach-Object { "  $_" } } else { "  vswhere not found (Visual Studio is probably not installed)" }
(Get-Command cl).Source | ForEach-Object { "  on PATH: $_" }

Write-Host "`n== make / Git / WSL =="
foreach ($c in 'make','mingw32-make','git','wsl') { $p = (Get-Command $c).Source; "  {0,-14} {1}" -f $c, $(if ($p) { $p } else { 'not found' }) }
Write-Host "`nWSL distributions:"; wsl -l -v 2>$null
