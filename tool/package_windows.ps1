[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$bundle = Join-Path $root 'build/windows/x64/runner/Release'
$executable = Join-Path $bundle 'arcana_observatory.exe'
if (!(Test-Path -LiteralPath $executable -PathType Leaf)) {
    throw 'Run flutter build windows --release first.'
}

# App-local C++ runtime also supports Windows installations without Visual Studio.
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
$vs = & $vswhere -latest -prerelease -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (!$vs) { throw 'Visual Studio C++ build tools are required for packaging.' }
$redist = Join-Path $vs 'VC/Redist/MSVC'
$version = Get-ChildItem -Directory -LiteralPath $redist |
    Where-Object { $_.Name -match '^\d+\.\d+\.\d+$' } |
    Sort-Object { [version]$_.Name } -Descending |
    Where-Object { Test-Path (Join-Path $_.FullName 'x64/Microsoft.VC*.CRT') } |
    Select-Object -First 1
if (!$version) { throw 'The x64 Visual C++ redistributable was not found.' }
$runtime = Get-ChildItem (Join-Path $version.FullName 'x64/Microsoft.VC*.CRT/*.dll')
if (!$runtime) { throw 'The x64 runtime directory contains no DLLs.' }
$runtime | Copy-Item -Destination $bundle
$zip = Join-Path $root 'build/arcana-observatory-windows-x64.zip'
Compress-Archive -Path (Join-Path $bundle '*') -DestinationPath $zip -Force
Get-Item -LiteralPath $zip | Select-Object FullName,Length
