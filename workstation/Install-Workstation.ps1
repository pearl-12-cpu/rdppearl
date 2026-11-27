# Run interactively on a Windows machine you own or administer.
[CmdletBinding()]
param(
    [ValidateSet('Core','Media','Full')][string]$Profile = 'Media',
    [string]$Workspace = (Join-Path $HOME 'APTRDP-Workspace'),
    [switch]$PlanOnly
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$config = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'config/apps.json') -Raw | ConvertFrom-Json
$packages = @($config.profiles.core)
if ($Profile -in 'Media','Full') { $packages += @($config.profiles.media) }
if ($Profile -eq 'Full') { $packages += @($config.profiles.optional) }
$packages = @($packages | Select-Object -Unique)
if ($PlanOnly) {
    $packages | ForEach-Object { Write-Output $_ }
    return
}
if ($env:GITHUB_ACTIONS -eq 'true') { throw 'Workstation provisioning is intended for an authorized dedicated machine, not a CI job.' }
if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
    throw 'Windows Package Manager is required. Install or update Microsoft App Installer first.'
}
foreach ($dir in 'Downloads','Projects','Exports','Logs') {
    New-Item -ItemType Directory -Path (Join-Path $Workspace $dir) -Force | Out-Null
}
$log = Join-Path $Workspace ('Logs/install-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.log')
$failures = [System.Collections.Generic.List[string]]::new()
Start-Transcript -Path $log | Out-Null
try {
    foreach ($id in $packages) {
        & winget.exe list --id $id --exact --accept-source-agreements --disable-interactivity
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Already installed: $id"
            continue
        }
        Write-Host "Installing $id"
        & winget.exe install --id $id --exact --source winget --accept-source-agreements --accept-package-agreements --disable-interactivity --no-upgrade
        $installCode = $LASTEXITCODE
        & winget.exe list --id $id --exact --accept-source-agreements --disable-interactivity
        $listCode = $LASTEXITCODE
        if ($installCode -ne 0 -or $listCode -ne 0) {
            $failures.Add("$id (install=$installCode, verify=$listCode)")
        }
    }
    $desktop = [Environment]::GetFolderPath('Desktop')
    if ($desktop -and (Test-Path -LiteralPath $desktop)) {
        $shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut((Join-Path $desktop 'APTRDP Workspace.lnk'))
        $shortcut.TargetPath = $Workspace
        $shortcut.Save()
    }
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Download-Media.ps1') -Destination $Workspace -Force
    if ($failures.Count -gt 0) { throw ('Package checks failed: ' + ($failures -join '; ')) }
    Write-Host "Provisioning finished. Open a new PowerShell window to refresh PATH. Log: $log"
} finally {
    Stop-Transcript | Out-Null
}
