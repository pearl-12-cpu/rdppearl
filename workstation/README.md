# APTRDP v2 — workstation prototype

Provision a Windows PC or dedicated VM you own or administer. GitHub Actions only validates source and installation plans; it does not host a remote desktop. The existing workflow is unchanged.

## Profiles

Core: browser, VLC, archive manager and process diagnostics. Media (default): adds FFmpeg, yt-dlp, LosslessCut, HandBrake, Audacity and Subtitle Edit. Full: adds qBittorrent. Only download or share authorized content.

## Usage

On the Windows machine, install Microsoft App Installer (winget) if absent. From the repository root in PowerShell:

```powershell
.\workstation\Install-Workstation.ps1 -Profile Media -PlanOnly
.\workstation\tests\Test-Workstation.ps1
.\workstation\Install-Workstation.ps1 -Profile Media
````

Open a new terminal after installation for updated PATH. The workspace contains Downloads, Projects, Exports and Logs. The media script is copied into the workspace. It accepts a permitted media URL and creates Windows-safe filenames without batch expansion.

Use a dedicated non-administrator account for desktop access; enable NLA and restrict RDP to a private network or your VM provider's access gateway. Never publish credentials or place them in workflow logs. This prototype does not open ports, create accounts, provision cloud infrastructure, or configure a tunnel. Backup persistent workspace data separately.

Winget verifies installer hashes against its package manifests; this prototype does not independently audit publishers or pin individual package versions. Package availability and actual installations need validation on the target VM. GUI apps use their normal Start menu entries. No dashboard, backup automation or graphical downloader is implemented yet.
