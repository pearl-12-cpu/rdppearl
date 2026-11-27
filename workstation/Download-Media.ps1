[CmdletBinding()]
param(
    [Parameter(Mandatory)][uri]$Url,
    [string]$Destination = (Join-Path $PSScriptRoot 'Downloads')
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $Url.IsAbsoluteUri -or $Url.Scheme -notin 'http','https') { throw 'Supply an absolute HTTP or HTTPS media URL.' }
if (-not (Get-Command yt-dlp -ErrorAction SilentlyContinue)) { throw 'yt-dlp not found. Open a new terminal after provisioning.' }
New-Item -ItemType Directory -Path $Destination -Force | Out-Null
# Download only media you have permission to download.
& yt-dlp --no-playlist --windows-filenames --paths $Destination -o '%(title)s-%(id)s.%(ext)s' -- $Url.AbsoluteUri
if ($LASTEXITCODE -ne 0) { throw "yt-dlp failed (exit $LASTEXITCODE)." }
