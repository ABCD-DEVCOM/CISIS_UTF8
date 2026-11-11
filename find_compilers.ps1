# find_compilers.ps1 - mostra quais compiladores do CISIS existem neste Windows.
# Uso (PowerShell):  powershell -ExecutionPolicy Bypass -File .\find_compilers.ps1
$ErrorActionPreference = 'SilentlyContinue'
Write-Host "== Borland C++ 5.5 (compilador dos .exe oficiais) =="
$bcc = @('C:\Borland\BCC55\Bin\bcc32.exe') + (Get-ChildItem 'C:\' -Directory -Filter 'Borland*' | ForEach-Object { Join-Path $_.FullName 'BCC55\Bin\bcc32.exe' })
$found = $bcc | Where-Object { Test-Path $_ } | Select-Object -Unique
if ($found) { $found | ForEach-Object { "  ENCONTRADO: $_" } } else { "  nao encontrado" }
(Get-Command bcc32).Source | ForEach-Object { "  no PATH: $_" }

Write-Host "`n== GCC / MinGW / MSYS2 / Dev-C++ / CodeBlocks =="
$cand = @('C:\msys64\mingw64\bin\gcc.exe','C:\msys64\mingw32\bin\gcc.exe','C:\msys64\ucrt64\bin\gcc.exe',
          'C:\Dev-Cpp\bin\gcc.exe','C:\Dev-Cpp\MinGW64\bin\gcc.exe','C:\MinGW\bin\gcc.exe',
          'C:\Program Files (x86)\CodeBlocks\MinGW\bin\gcc.exe','C:\Program Files\CodeBlocks\MinGW\bin\gcc.exe',
          'C:\Win-Builds\bin\gcc.exe')
$cand | Where-Object { Test-Path $_ } | ForEach-Object { "  $_  ->  " + (& $_ --version | Select-Object -First 1) }
Get-Command gcc | ForEach-Object { "  no PATH: $($_.Source)  ->  " + (& $_.Source --version | Select-Object -First 1) }

Write-Host "`n== Microsoft Visual Studio (cl.exe) =="
$vsw = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vsw) { & $vsw -latest -products * -property installationPath | ForEach-Object { "  $_" } } else { "  vswhere nao encontrado (provavelmente sem Visual Studio)" }
(Get-Command cl).Source | ForEach-Object { "  no PATH: $_" }

Write-Host "`n== make / Git / WSL =="
foreach ($c in 'make','mingw32-make','git','wsl') { $p = (Get-Command $c).Source; "  {0,-14} {1}" -f $c, $(if ($p) { $p } else { 'nao encontrado' }) }
Write-Host "`nDistribuicoes WSL:"; wsl -l -v 2>$null
