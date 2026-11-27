Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
foreach ($file in Get-ChildItem -LiteralPath $root -Filter '*.ps1' -Recurse) {
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors) | Out-Null
    if ($errors.Count -gt 0) { throw "PowerShell parse failure: $($file.Name): $errors" }
}
$config = Get-Content -LiteralPath (Join-Path $root 'config/apps.json') -Raw | ConvertFrom-Json
if ($config.schemaVersion -ne 1) { throw 'Unexpected manifest schema.' }
$all = @($config.profiles.core) + @($config.profiles.media) + @($config.profiles.optional)
if (@($all | Select-Object -Unique).Count -ne $all.Count) { throw 'Duplicate package IDs.' }
foreach ($id in $all) { if ($id -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]+$') { throw "Invalid package ID: $id" } }
$installer = Join-Path $root 'Install-Workstation.ps1'
$core = @(& $installer -Profile Core -PlanOnly)
$media = @(& $installer -Profile Media -PlanOnly)
$full = @(& $installer -Profile Full -PlanOnly)
if ($core.Count -ne $config.profiles.core.Count -or $media.Count -ne ($config.profiles.core.Count + $config.profiles.media.Count) -or $full.Count -ne $all.Count) { throw 'Unexpected profile selection.' }
if (@(Compare-Object -ReferenceObject $all -DifferenceObject $full).Count -ne 0) { throw 'Full profile differs from manifest.' }
Write-Host 'PASS: syntax, manifest, and installation plan checks.'
