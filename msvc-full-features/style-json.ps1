$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
Set-Location -Path (Join-Path -Path $scriptDir -ChildPath "..")
$blacklist = Get-Content "msvc-full-features\json_blacklist" | Resolve-Path -Relative
$files = Get-ChildItem -Recurse -Include *.json "data" | Resolve-Path -Relative | ?{$blacklist -notcontains $_}
$files | ForEach-Object { Invoke-Expression ".\msvc-full-features\tools\format\json_formatter.exe $_" }
