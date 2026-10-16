# GD Remote: set (or rotate) the permanent password of this Windows host.
# Run as Administrator on the controlled machine, after installation.
# Generates a 16-character password (upper, lower, digits), applies it through
# the installed service, prints the device ID and the password once: store
# them in the password manager, they are not saved anywhere else.
# Usage: powershell -ExecutionPolicy Bypass -File gd-remote-set-password.ps1 [-Password <value>]
param([string] $Password)
$ErrorActionPreference = "Stop"
$exe = Join-Path $env:ProgramFiles "GD-Remote\GD-Remote.exe"
if (-not (Test-Path $exe)) { throw "GD Remote is not installed ($exe)" }
if (-not $Password) {
  $alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789".ToCharArray()
  do {
    $bytes = New-Object byte[] 16
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    $Password = -join ($bytes | ForEach-Object { $alphabet[$_ % $alphabet.Length] })
  } until ($Password -cmatch "[A-Z]" -and $Password -cmatch "[a-z]" -and $Password -match "[0-9]")
}
if ($Password.Length -lt 12) { throw "password must be at least 12 characters" }
$out = & $exe --password $Password 2>&1
if ($out -notmatch "Done") { throw "setting the password failed: $out" }
$id = (& $exe --get-id 2>&1 | Select-Object -Last 1).Trim()
Write-Host "Device ID : $id"
Write-Host "Password  : $Password"
