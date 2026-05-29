<#
.SYNOPSIS
    Validate core JSON (and optionally a specific mod) by finalizing the game data
    with the built binary. The sanctioned verification for JSON edits / BN imports.

.DESCRIPTION
    Runs `Cataclysm-cuphwi.exe --check-mods <mod>` which always loads core data,
    the named mod and its dependencies, then runs finalize + check_consistency.

    Exit 0 from the binary means a STRICT pass: zero load errors AND zero debugmsg
    warnings (see game.cpp check_mod_data: returns `... && !test_dirty`).

    IMPORTANT: do NOT run `--check-mods` with no arguments. That checks every mod
    including the bundled Lua mods, whose items reference iuse actions registered at
    runtime by other mods' Lua; the static pass can't resolve them and crashes with
    an access violation (0xC0000005). Lua mods are verified by in-game runtime, not
    by this tool. This script therefore checks a curated non-Lua set by default.

.PARAMETER Mods
    One or more non-Lua mod idents to check (core is always loaded). Defaults to
    `alt_map_key` — a tiny non-Lua mod used purely as a probe so that core JSON
    (the usual landing spot for BN imports) gets finalized and checked.

.EXAMPLE
    pwsh tools/check-json.ps1
    # validates core JSON

.EXAMPLE
    pwsh tools/check-json.ps1 my_bn_mod
    # validates core JSON + my_bn_mod (+ its dependencies)
#>
param(
    [string[]]$Mods = @( 'alt_map_key' )
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$exe  = Join-Path $repo 'Cataclysm-cuphwi.exe'

if( -not ( Test-Path $exe ) ) {
    Write-Host "ERROR: $exe not found. Build Release|x64 first." -ForegroundColor Red
    exit 2
}

Write-Host "Checking core JSON + mods: $($Mods -join ', ')" -ForegroundColor Cyan

# The binary is a GUI-subsystem app (USE_WINMAIN); use Start-Process -Wait so we
# reliably block until it exits and capture a real ExitCode plus its output.
$outFile = [System.IO.Path]::GetTempFileName()
$errFile = [System.IO.Path]::GetTempFileName()
$procArgs = @( '--check-mods' ) + $Mods
$proc = Start-Process -FilePath $exe -ArgumentList $procArgs -WorkingDirectory $repo `
    -NoNewWindow -Wait -PassThru -RedirectStandardOutput $outFile -RedirectStandardError $errFile
$code = $proc.ExitCode

$text = ( Get-Content $outFile, $errFile -EA SilentlyContinue ) -join "`n"
$text | Write-Host
Remove-Item $outFile, $errFile -EA SilentlyContinue

# The binary prints an authoritative "CHECK_MODS_RESULT: PASS/FAIL" marker right
# after the check, then std::_Exit(0/1). Trust the marker first (the exit code is
# also reliable now, but the marker is immune to any future teardown quirks).
if( $text -match 'CHECK_MODS_RESULT:\s*PASS' ) {
    Write-Host "`nPASS: no load errors or consistency warnings." -ForegroundColor Green
    exit 0
} elseif( $text -match 'CHECK_MODS_RESULT:\s*FAIL' ) {
    Write-Host "`nFAIL: load errors or consistency warnings (see above)." -ForegroundColor Red
    exit 1
} else {
    Write-Host "`nFAIL (no result marker; exit $code): the binary likely crashed before finishing the check." -ForegroundColor Red
    exit 1
}
