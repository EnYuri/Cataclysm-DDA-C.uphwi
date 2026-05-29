<#
.SYNOPSIS
    Heuristic audit for Bright Nights (or any) JSON imports: flags object keys that
    the C++ source never reads, so silently-ignored fields don't slip in unnoticed.

.DESCRIPTION
    This 0.D-era fork's JsonObject does NOT track unvisited members, so JSON with
    fields the C++ schema doesn't recognize loads WITHOUT error -- the extra fields
    just silently do nothing. When importing BN content this is the main failure
    mode: the data loads, but a feature quietly doesn't work.

    This script parses a JSON file, gathers every key used (recursively), and checks
    whether each key appears anywhere in src/ as a quoted string literal ("key").
    Keys with zero hits are almost certainly ignored by the loader and are reported
    for review.

    It also checks string values under flag keys (default: "flags") the same way,
    reporting flag values that never appear in src/ as UNKNOWN FLAGS.

    It is a HEURISTIC, not a proof:
      * False positives: a key/flag only consumed via a constructed/variable name, a
        flag defined in JSON (json_flag) rather than hardcoded in src/, or one that
        genuinely is unused. Review before assuming a field/flag is dead.
      * False "OK": a key/flag string that appears in src/ for an unrelated reason
        still counts as recognized. Cross-check the actual load() if in doubt.

.PARAMETER JsonFile
    Path to the JSON file to audit (an array of objects, or a single object).

.PARAMETER ShowRecognized
    Also list the keys that ARE found in src/ (default: only report likely-ignored).

.EXAMPLE
    pwsh tools/bn-import-audit.ps1 data/json/some_bn_import.json
#>
param(
    [Parameter(Mandatory = $true)][string]$JsonFile,
    [switch]$ShowRecognized,
    # Keys whose string values are treated as flags and checked against src/.
    [string[]]$FlagKeys = @( 'flags' )
)

$ErrorActionPreference = 'Stop'
$repo   = Split-Path -Parent $PSScriptRoot
$srcDir = Join-Path $repo 'src'

if( -not ( Test-Path $JsonFile ) ) {
    Write-Host "ERROR: $JsonFile not found." -ForegroundColor Red
    exit 2
}

# Load all C++ source once for fast substring lookups.
Write-Host "Indexing src/ ..." -ForegroundColor DarkGray
$allSrc = ( Get-ChildItem $srcDir -Recurse -File -Include *.cpp, *.h |
            Get-Content -Raw -ErrorAction SilentlyContinue ) -join "`n"

# Keys that are structural/loader-handled and never worth flagging.
$ignoreKeys = @( 'type', 'id', 'abstract', 'copy-from', 'edit-mode', 'comment', '//' )

$json = Get-Content -Raw $JsonFile | ConvertFrom-Json
$objects = if( $json -is [System.Collections.IEnumerable] -and $json -isnot [string] ) { $json } else { @( $json ) }

# Recursively collect keys from an object graph into a HashSet.
function Add-Keys {
    param( $node, [System.Collections.Generic.HashSet[string]]$set )
    if( $null -eq $node ) { return }
    if( $node -is [System.Management.Automation.PSCustomObject] ) {
        foreach( $p in $node.PSObject.Properties ) {
            [void]$set.Add( $p.Name )
            Add-Keys $p.Value $set
        }
    } elseif( $node -is [System.Collections.IEnumerable] -and $node -isnot [string] ) {
        foreach( $item in $node ) { Add-Keys $item $set }
    }
}

# Recursively collect string values whose immediate parent key is a flag key.
function Add-Flags {
    param( $node, [string]$parentKey, [System.Collections.Generic.HashSet[string]]$set )
    if( $null -eq $node ) { return }
    if( $node -is [System.Management.Automation.PSCustomObject] ) {
        foreach( $p in $node.PSObject.Properties ) { Add-Flags $p.Value $p.Name $set }
    } elseif( $node -is [System.Collections.IEnumerable] -and $node -isnot [string] ) {
        foreach( $item in $node ) { Add-Flags $item $parentKey $set }
    } elseif( $node -is [string] ) {
        if( $FlagKeys -contains $parentKey ) { [void]$set.Add( $node ) }
    }
}

$recognizedCache = @{}
function Test-KeyKnown {
    param( [string]$key )
    if( $recognizedCache.ContainsKey( $key ) ) { return $recognizedCache[$key] }
    $known = $allSrc.Contains( '"' + $key + '"' )
    $recognizedCache[$key] = $known
    return $known
}

$totalIgnored = 0
$idx = 0
foreach( $obj in $objects ) {
    $idx++
    if( $obj -isnot [System.Management.Automation.PSCustomObject] ) { continue }
    $label = $obj.type
    if( $obj.id )    { $label = "$label / $($obj.id)" }
    elseif( $obj.abstract ) { $label = "$label / abstract:$($obj.abstract)" }

    $keys = [System.Collections.Generic.HashSet[string]]::new()
    Add-Keys $obj $keys

    $ignored    = @()
    $recognized = @()
    foreach( $k in $keys ) {
        if( $ignoreKeys -contains $k ) { continue }
        if( Test-KeyKnown $k ) { $recognized += $k } else { $ignored += $k }
    }

    # Collect and check flag values (string values under FlagKeys).
    $flags = [System.Collections.Generic.HashSet[string]]::new()
    Add-Flags $obj $null $flags
    $unknownFlags = @()
    foreach( $f in $flags ) {
        if( -not ( Test-KeyKnown $f ) ) { $unknownFlags += $f }
    }

    if( $ignored.Count -gt 0 -or $unknownFlags.Count -gt 0 -or $ShowRecognized ) {
        Write-Host "`n[$idx] $label" -ForegroundColor Cyan
        if( $ignored.Count -gt 0 ) {
            Write-Host ( "  LIKELY IGNORED: " + ( ( $ignored | Sort-Object ) -join ', ' ) ) -ForegroundColor Yellow
        }
        if( $unknownFlags.Count -gt 0 ) {
            Write-Host ( "  UNKNOWN FLAGS:  " + ( ( $unknownFlags | Sort-Object ) -join ', ' ) ) -ForegroundColor Yellow
        }
        if( $ShowRecognized -and $recognized.Count -gt 0 ) {
            Write-Host ( "  recognized:     " + ( ( $recognized | Sort-Object ) -join ', ' ) ) -ForegroundColor DarkGray
        }
    }
    $totalIgnored += $ignored.Count + $unknownFlags.Count
}

Write-Host ""
if( $totalIgnored -eq 0 ) {
    Write-Host "No unrecognized keys or flags found (all appear in src/). Heuristic only -- verify wiring for new features." -ForegroundColor Green
} else {
    Write-Host "$totalIgnored likely-ignored key/flag occurrence(s) flagged. Review each: wire it in C++, or confirm it's a JSON-defined flag / intentionally unsupported." -ForegroundColor Yellow
}
