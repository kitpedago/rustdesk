# GD Remote: sign the Windows installer published by CI with Certum SimplySign
# (Code Signing in the Cloud, non-exportable key) and re-upload it to the release.
#
# Prerequisites on this Windows PC: SimplySign Desktop connected (virtual card
# online), Windows 10/11 SDK signing tools, GitHub CLI logged in.
# Usage: powershell -ExecutionPolicy Bypass -File res\gd-remote-sign.ps1 -Tag dev -Repo <owner>/rustdesk
param(
  [Parameter(Mandatory)] [string] $Tag,
  [Parameter(Mandatory)] [string] $Repo,
  [string] $Subject = "SARL IN SET",
  [string] $Timestamp = "http://time.certum.pl"
)
$ErrorActionPreference = "Stop"
$signtool = Get-ChildItem "${env:ProgramFiles(x86)}\Windows Kits\10\bin\*\x64\signtool.exe" |
  Sort-Object FullName -Descending | Select-Object -First 1 -ExpandProperty FullName
if (-not $signtool) { throw "signtool.exe not found: install the Windows SDK signing tools" }

$dir = Join-Path $env:TEMP "gd-remote-sign-$Tag"
New-Item -ItemType Directory -Force $dir | Out-Null
gh release download $Tag -R $Repo -p "GD-Remote-*.exe" -D $dir --clobber
$files = @(Get-ChildItem "$dir\GD-Remote-*.exe" | Select-Object -ExpandProperty FullName)
if (-not $files) { throw "no GD-Remote-*.exe asset in release $Tag" }

& $signtool sign /n $Subject /fd sha256 /tr $Timestamp /td sha256 /v $files
if ($LASTEXITCODE) { throw "signtool sign failed ($LASTEXITCODE)" }
& $signtool verify /pa /v $files
if ($LASTEXITCODE) { throw "signature verification failed ($LASTEXITCODE)" }

gh release upload $Tag $files -R $Repo --clobber
Write-Host "signed and re-uploaded: $($files -join ', ')"
