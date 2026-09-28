param(
    [string]$Godot = $env:GODOT_BIN,
    [switch]$Visual
)
$ErrorActionPreference = 'Stop'
if (-not $Godot) {
    $localGodot = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Godot/Godot_v4.7.2-stable_win64_console.exe'
    if (Test-Path -LiteralPath $localGodot) { $Godot = $localGodot }
    else { $Godot = (Get-Command godot -ErrorAction Stop).Source }
}
$projectRoot = Split-Path $PSScriptRoot -Parent
function Invoke-CheckedGodot([string[]]$GodotArgs) {
    $output = & $Godot --path $projectRoot @GodotArgs 2>&1
    $code = $LASTEXITCODE
    $output | ForEach-Object { Write-Host $_ }
    if ($code -ne 0 -or ($output -match 'SCRIPT ERROR:|^ERROR:|^FAIL ')) {
        throw "Godot validation failed (exit $code)."
    }
}
Invoke-CheckedGodot @('--headless', '--editor', '--import', '--quit')
Invoke-CheckedGodot @('--headless', '--script', 'res://tests/player_milestone.gd')
Invoke-CheckedGodot @('--headless', '--script', 'res://tests/responsiveness.gd')
Invoke-CheckedGodot @('--headless', '--script', 'res://tests/items_core.gd')
Invoke-CheckedGodot @('--headless', '--script', 'res://tests/items_world.gd')
if ($Visual) {
    Invoke-CheckedGodot @('--script', 'res://tests/items_ui.gd')
    Invoke-CheckedGodot @('--script', 'res://tests/isometric_visibility.gd')
    Invoke-CheckedGodot @('--script', 'res://tests/edge_cases.gd')
    Invoke-CheckedGodot @('--script', 'res://tests/render_views.gd')
} else {
    Invoke-CheckedGodot @('--headless', '--script', 'res://tests/items_ui.gd')
    Invoke-CheckedGodot @('--headless', '--script', 'res://tests/isometric_visibility.gd')
    Invoke-CheckedGodot @('--headless', '--script', 'res://tests/edge_cases.gd')
}
Write-Host 'VALIDATION PASSED'
