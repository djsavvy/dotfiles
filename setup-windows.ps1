#Requires -Version 5.1

<#
.SYNOPSIS
    Applies this checkout's Windows settings and Startup shortcut.
.EXAMPLE
    .\setup-windows.ps1
    Run as administrator under your normal Windows account.
.EXAMPLE
    .\setup-windows.ps1 -WhatIf
    Preview changes without elevation or writes.
#>

[CmdletBinding(SupportsShouldProcess)]
param()

$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') { throw 'This setup script requires Windows.' }
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $WhatIfPreference -and -not $isAdmin) {
    throw 'Run setup-windows.ps1 from an administrator PowerShell under your normal Windows account, or use -WhatIf to preview.'
}

# Preferences: edit these values, then rerun setup.
$hibernateTimeoutMinutes = 20
$standbyConnectivityOnBattery = 0
$hotkeyScript = Join-Path $PSScriptRoot 'Custom Keys.ahk'
$powerShellProfile = Join-Path $PSScriptRoot 'Microsoft.PowerShell_profile.ps1'
$gitConfig = Join-Path $PSScriptRoot '.gitconfig'
$nvimConfig = Join-Path $PSScriptRoot '.config\nvim'
$terminalSettings = Join-Path $PSScriptRoot 'settings.json'
# Claude Code treats subfolders of a trusted folder as trusted, so this skips the
# "Do you trust the files in this folder?" prompt everywhere under it.
$claudeTrustedFolder = $env:USERPROFILE

function Invoke-PowerCfg {
    param([string[]]$Arguments)
    & powercfg.exe @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "powercfg $($Arguments -join ' ') failed (exit code $LASTEXITCODE)."
    }
}

function Set-AutoHotkeyStartupShortcut {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$Script, [string]$StartupDirectory)

    $shortcutPath = Join-Path $StartupDirectory 'Custom Keys.lnk'
    # Update the existing manually created shortcut instead of adding a duplicate.
    $legacyShortcutPath = Join-Path $StartupDirectory 'Custom Keys.exe - Shortcut.lnk'
    if (-not (Test-Path -LiteralPath $shortcutPath) -and (Test-Path -LiteralPath $legacyShortcutPath)) {
        $shortcutPath = $legacyShortcutPath
    }

    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $null
    try {
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $workingDirectory = Split-Path -LiteralPath $Script
        if ($shortcut.TargetPath -eq $Script -and [string]::IsNullOrEmpty($shortcut.Arguments) -and
            $shortcut.WorkingDirectory -eq $workingDirectory) {
            Write-Host 'AutoHotkey Startup shortcut is already configured.'
            return
        }
        if ($PSCmdlet.ShouldProcess($shortcutPath, "Point Startup shortcut at $Script")) {
            New-Item -ItemType Directory -Path $StartupDirectory -Force | Out-Null
            # Windows opens the script with its existing .ahk file association.
            $shortcut.TargetPath = $Script
            $shortcut.Arguments = ''
            $shortcut.WorkingDirectory = $workingDirectory
            $shortcut.Description = 'Keyboard shortcuts from dotfiles'
            $shortcut.Save()
        }
    }
    finally {
        if ($shortcut) { [Runtime.InteropServices.Marshal]::FinalReleaseComObject($shortcut) | Out-Null }
        [Runtime.InteropServices.Marshal]::FinalReleaseComObject($shell) | Out-Null
    }
}

function Set-ClaudeFolderTrust {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$Folder)

    $configPath = Join-Path $env:USERPROFILE '.claude.json'
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        Write-Host "Skipping Claude Code folder trust: $configPath not found. Run claude once, then rerun setup."
        return
    }
    # Claude Code keys projects by forward-slash paths.
    $key = $Folder.TrimEnd('\') -replace '\\', '/'

    $config = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not $config.PSObject.Properties['projects']) {
        $config | Add-Member -NotePropertyName projects -NotePropertyValue ([pscustomobject]@{})
    }
    $project = $config.projects.PSObject.Properties[$key]
    if ($project -and $project.Value.hasTrustDialogAccepted -eq $true) {
        Write-Host "Claude Code already trusts $key."
        return
    }
    if ($PSCmdlet.ShouldProcess($configPath, "Trust $key and its subfolders in Claude Code")) {
        if (-not $project) {
            $config.projects | Add-Member -NotePropertyName $key -NotePropertyValue ([pscustomobject]@{})
            $project = $config.projects.PSObject.Properties[$key]
        }
        $project.Value | Add-Member -NotePropertyName hasTrustDialogAccepted -NotePropertyValue $true -Force
        Copy-Item -LiteralPath $configPath -Destination "$configPath.bak" -Force
        # Running Claude Code sessions may overwrite this on exit; close them first.
        [IO.File]::WriteAllText($configPath, ($config | ConvertTo-Json -Depth 100), (New-Object Text.UTF8Encoding $false))
    }
}

function Set-PowerShellProfileStub {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$Source)

    # Setup may run under Windows PowerShell, so build the pwsh path instead of using
    # $PROFILE. GetFolderPath follows OneDrive's Documents redirection. profile.ps1 is
    # the all-hosts profile, so the VS Code extension loads it too.
    $profileDirectory = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell'
    $stubPath = Join-Path $profileDirectory 'profile.ps1'
    # Dot-source instead of symlinking: no Developer Mode needed, and OneDrive and
    # editors can't swap the link for a copy.
    $stub = ". '$($Source -replace "'", "''")'"

    # An earlier symlinked host profile would load the dotfile a second time.
    $hostProfile = Join-Path $profileDirectory 'Microsoft.PowerShell_profile.ps1'
    $hostItem = Get-Item -LiteralPath $hostProfile -Force -ErrorAction SilentlyContinue
    if ($hostItem -and $hostItem.LinkType -eq 'SymbolicLink' -and
        $PSCmdlet.ShouldProcess($hostProfile, 'Remove old profile symlink')) {
        $hostItem.Delete()
    }

    $stubItem = Get-Item -LiteralPath $stubPath -Force -ErrorAction SilentlyContinue
    if ($stubItem -and -not $stubItem.LinkType -and
        (Get-Content -LiteralPath $stubPath -Raw).Trim() -eq $stub) {
        Write-Host 'PowerShell profile stub is already configured.'
        return
    }
    if ($PSCmdlet.ShouldProcess($stubPath, "Dot-source $Source")) {
        New-Item -ItemType Directory -Path $profileDirectory -Force | Out-Null
        if ($stubItem -and $stubItem.LinkType) {
            $stubItem.Delete()
        }
        elseif ($stubItem) {
            Copy-Item -LiteralPath $stubPath -Destination "$stubPath.bak" -Force
        }
        [IO.File]::WriteAllText($stubPath, "$stub`r`n", (New-Object Text.UTF8Encoding $false))
    }
}

function Set-GitConfigStub {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$Source)

    $stubPath = Join-Path $env:USERPROFILE '.gitconfig'
    $ignorePath = Join-Path (Split-Path -Parent $Source) '.gitignore_global'
    # Settings below the include override the shared config. Git for Windows' system
    # config already provides credential.helper = manager.
    $stub = @(
        '[include]'
        "`tpath = $($Source -replace '\\', '/')"
        '[core]'
        # Read the ignore list from the checkout instead of copying it to ~.
        "`texcludesfile = $($ignorePath -replace '\\', '/')"
        "`tlongpaths = true"
        "`tfsmonitor = true"
        "`tuntrackedcache = true"
    ) -join "`n"

    $stubItem = Get-Item -LiteralPath $stubPath -Force -ErrorAction SilentlyContinue
    if ($stubItem -and -not $stubItem.LinkType -and
        ((Get-Content -LiteralPath $stubPath -Raw).Trim() -replace "`r`n", "`n") -eq $stub) {
        Write-Host 'Git config stub is already configured.'
        return
    }
    if ($PSCmdlet.ShouldProcess($stubPath, "Include $Source")) {
        if ($stubItem -and $stubItem.LinkType) {
            $stubItem.Delete()
        }
        elseif ($stubItem) {
            Copy-Item -LiteralPath $stubPath -Destination "$stubPath.bak" -Force
        }
        [IO.File]::WriteAllText($stubPath, "$stub`n", (New-Object Text.UTF8Encoding $false))
    }
}

function Set-NvimConfigJunction {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$Source)

    # A junction rather than a stub init.lua, so spell files added with zg land in
    # the checkout too. Junctions don't need Developer Mode.
    $linkPath = Join-Path $env:LOCALAPPDATA 'nvim'
    $item = Get-Item -LiteralPath $linkPath -Force -ErrorAction SilentlyContinue
    if (-not $item) {
        if ($PSCmdlet.ShouldProcess($linkPath, "Create junction to $Source")) {
            New-Item -ItemType Junction -Path $linkPath -Target $Source | Out-Null
        }
        return
    }
    if ($item.LinkType -eq 'Junction' -and "$($item.Target)".TrimEnd('\') -eq $Source.TrimEnd('\')) {
        Write-Host 'Neovim config junction is already configured.'
        return
    }
    # Don't replace an existing config; the user decides what to keep.
    $found = if ($item.LinkType) { "a $($item.LinkType) to $($item.Target)" }
        elseif ($item.PSIsContainer) { 'an existing folder' }
        else { 'a file' }
    throw "$linkPath is $found, expected a junction to $Source. Move it aside and rerun setup."
}

function Set-TerminalSettingsLink {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$Source)

    $packageDirectory = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe'
    if (-not (Test-Path -LiteralPath $packageDirectory)) {
        Write-Host 'Skipping Windows Terminal Preview settings: not installed.'
        return
    }
    # Terminal has no include mechanism and rewrites this file from its settings UI,
    # so a stub or copy would drift. Symlinks need Developer Mode or elevation.
    $linkPath = Join-Path $packageDirectory 'LocalState\settings.json'
    $item = Get-Item -LiteralPath $linkPath -Force -ErrorAction SilentlyContinue
    if ($item -and $item.LinkType -eq 'SymbolicLink' -and "$($item.Target)" -eq $Source) {
        Write-Host 'Windows Terminal Preview settings link is already configured.'
        return
    }
    if ($item -and $item.LinkType) {
        throw "$linkPath is a $($item.LinkType) to $($item.Target), expected a symlink to $Source. Move it aside and rerun setup."
    }
    if ($PSCmdlet.ShouldProcess($linkPath, "Link to $Source")) {
        New-Item -ItemType Directory -Path (Split-Path -Parent $linkPath) -Force | Out-Null
        # Terminal generates a default file on first launch, so back it up rather than
        # failing on every new machine.
        if ($item) {
            Copy-Item -LiteralPath $linkPath -Destination "$linkPath.bak" -Force
            Remove-Item -LiteralPath $linkPath -Force
        }
        New-Item -ItemType SymbolicLink -Path $linkPath -Target $Source | Out-Null
    }
}

if (-not (Test-Path -LiteralPath $hotkeyScript -PathType Leaf)) {
    throw "Missing hotkey script: $hotkeyScript. Run setup from a complete dotfiles checkout."
}

# Add future setup steps below. Guard writes with ShouldProcess for -WhatIf.

# 1. Add Custom Keys.ahk to shell:startup for the current user.
Set-AutoHotkeyStartupShortcut -Script $hotkeyScript -StartupDirectory ([Environment]::GetFolderPath('Startup'))

# 2. Battery preferences for the current power plan. AC settings stay unchanged.
if ($PSCmdlet.ShouldProcess('Current Windows power plan', "Set battery hibernation to $hibernateTimeoutMinutes minutes and standby connectivity to $standbyConnectivityOnBattery")) {
    Invoke-PowerCfg -Arguments @('/change', 'hibernate-timeout-dc', "$hibernateTimeoutMinutes")
    Invoke-PowerCfg -Arguments @('/setdcvalueindex', 'SCHEME_CURRENT', 'SUB_NONE', 'CONNECTIVITYINSTANDBY', "$standbyConnectivityOnBattery")
    Invoke-PowerCfg -Arguments @('/setactive', 'SCHEME_CURRENT')
}

# 3. Skip Claude Code's folder trust prompt under the trusted folder.
Set-ClaudeFolderTrust -Folder $claudeTrustedFolder

# 4. Load the dotfiles PowerShell profile from pwsh's profile directory.
Set-PowerShellProfileStub -Source $powerShellProfile

# 5. Load the dotfiles git config from ~/.gitconfig.
Set-GitConfigStub -Source $gitConfig

# 6. Point Neovim's config directory at the checkout.
Set-NvimConfigJunction -Source $nvimConfig

# 7. Point Windows Terminal Preview's settings at the checkout.
Set-TerminalSettingsLink -Source $terminalSettings

if (-not $WhatIfPreference) {
    Write-Host 'Windows setup complete. The hotkey script will run at your next sign-in.'
}
