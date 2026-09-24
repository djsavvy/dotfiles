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

if (-not $WhatIfPreference) {
    Write-Host 'Windows setup complete. The hotkey script will run at your next sign-in.'
}
