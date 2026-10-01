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
$gitBashProfile = Join-Path $PSScriptRoot 'gitbash.bashrc'
$nvimConfig = Join-Path $PSScriptRoot '.config\nvim'
$terminalSettings = Join-Path $PSScriptRoot 'settings.json'
$atuinConfig = Join-Path $PSScriptRoot '.config\atuin\config.toml'
$zedConfigDir = Join-Path $PSScriptRoot '.config\zed'
$piWorkProfile = Join-Path $PSScriptRoot 'profiles\work\.pi'
# Claude Code treats subfolders of a trusted folder as trusted, so this skips the
# "Do you trust the files in this folder?" prompt everywhere under it.
$claudeTrustedFolder = $env:USERPROFILE
# Defender real-time scanning makes yarn installs and builds under here very slow.
$defenderExcludedFolder = Join-Path $env:USERPROFILE 'src'

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

function Add-DefenderExclusion {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$Folder)

    $existing = @((Get-MpPreference).ExclusionPath)
    if ($existing -contains $Folder) {
        Write-Host "Defender already excludes $Folder."
        return
    }
    if ($PSCmdlet.ShouldProcess($Folder, 'Add Microsoft Defender exclusion')) {
        Add-MpPreference -ExclusionPath $Folder
        # Org policy (Intune/GPO) can override local exclusions without erroring.
        if (@((Get-MpPreference).ExclusionPath) -notcontains $Folder) {
            Write-Warning "Defender did not keep the exclusion for $Folder; it may be overridden by policy."
        }
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

function Set-BashrcStub {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$Source)

    # Source instead of symlinking, like the PowerShell and git config stubs. Git
    # Bash creates a ~/.bash_profile that loads ~/.bashrc on its first launch.
    $stubPath = Join-Path $env:USERPROFILE '.bashrc'
    $stub = ". '$($Source -replace '\\', '/')'"

    $stubItem = Get-Item -LiteralPath $stubPath -Force -ErrorAction SilentlyContinue
    if ($stubItem -and -not $stubItem.LinkType -and
        ((Get-Content -LiteralPath $stubPath -Raw).Trim() -replace "`r`n", "`n") -eq $stub) {
        Write-Host 'Git Bash profile stub is already configured.'
        return
    }
    if ($PSCmdlet.ShouldProcess($stubPath, "Source $Source")) {
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

function Set-AtuinConfigLink {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$Source)

    # Atuin reads config.toml but never writes to it (sync/session data go in the
    # data directory), so a symlink is safe. Use a symlink rather than a stub: TOML
    # has no include mechanism.
    $linkPath = Join-Path $env:USERPROFILE '.config\atuin\config.toml'
    $item = Get-Item -LiteralPath $linkPath -Force -ErrorAction SilentlyContinue
    if ($item -and $item.LinkType -eq 'SymbolicLink' -and "$($item.Target)" -eq $Source) {
        Write-Host 'Atuin config link is already configured.'
        return
    }
    if ($item -and $item.LinkType) {
        throw "$linkPath is a $($item.LinkType) to $($item.Target), expected a symlink to $Source. Move it aside and rerun setup."
    }
    if ($PSCmdlet.ShouldProcess($linkPath, "Link to $Source")) {
        New-Item -ItemType Directory -Path (Split-Path -Parent $linkPath) -Force | Out-Null
        if ($item) {
            Copy-Item -LiteralPath $linkPath -Destination "$linkPath.bak" -Force
            Remove-Item -LiteralPath $linkPath -Force
        }
        New-Item -ItemType SymbolicLink -Path $linkPath -Target $Source | Out-Null
    }
}

function Add-UserPath {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$Directory)

    $current = [Environment]::GetEnvironmentVariable('Path', 'User') ?? ''
    # Split and filter empties so a trailing semicolon doesn't create a blank entry.
    $parts = @($current -split ';' | Where-Object { $_ -ne '' })
    if ($parts -contains $Directory) {
        Write-Host "User PATH already contains $Directory."
        return
    }
    $newPath = ($parts + $Directory) -join ';'
    if ($PSCmdlet.ShouldProcess('User PATH', "Add $Directory")) {
        [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    }
}

function Set-ZedConfigLinks {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$SourceDir)

    $zedDir = Join-Path $env:APPDATA 'Zed'
    $allConfigured = $true
    foreach ($name in 'settings.json', 'keymap.json') {
        $src = Join-Path $SourceDir $name
        $linkPath = Join-Path $zedDir $name
        $item = Get-Item -LiteralPath $linkPath -Force -ErrorAction SilentlyContinue
        if ($item -and $item.LinkType -eq 'SymbolicLink' -and "$($item.Target)" -eq $src) {
            Write-Host "Zed $name link is already configured."
            continue
        }
        if ($item -and $item.LinkType) {
            throw "$linkPath is a $($item.LinkType) to $($item.Target), expected a symlink to $src. Move it aside and rerun setup."
        }
        $allConfigured = $false
        if ($PSCmdlet.ShouldProcess($linkPath, "Link to $src")) {
            New-Item -ItemType Directory -Path $zedDir -Force | Out-Null
            if ($item) {
                Copy-Item -LiteralPath $linkPath -Destination "$linkPath.bak" -Force
                Remove-Item -LiteralPath $linkPath -Force
            }
            New-Item -ItemType SymbolicLink -Path $linkPath -Target $src | Out-Null
        }
    }
}

function Set-PiWorkProfile {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$SourceDir)

    # Mirror profiles/work/.pi into ~/.pi using symlinks. pi has no include
    # mechanism so we link each file/folder individually.
    $piDir = Join-Path $env:USERPROFILE '.pi'
    $allConfigured = $true
    foreach ($entry in Get-ChildItem -LiteralPath $SourceDir -Recurse -Force) {
        $rel = $entry.FullName.Substring($SourceDir.Length).TrimStart('\')
        $linkPath = Join-Path $piDir $rel
        if ($entry.PSIsContainer) {
            if (-not (Test-Path -LiteralPath $linkPath)) {
                if ($PSCmdlet.ShouldProcess($linkPath, 'Create directory')) {
                    New-Item -ItemType Directory -Path $linkPath -Force | Out-Null
                }
            }
            continue
        }
        $item = Get-Item -LiteralPath $linkPath -Force -ErrorAction SilentlyContinue
        if ($item -and $item.LinkType -eq 'SymbolicLink' -and "$($item.Target)" -eq $entry.FullName) {
            continue
        }
        if ($item -and $item.LinkType) {
            throw "$linkPath is a $($item.LinkType) to $($item.Target), expected a symlink to $($entry.FullName). Move it aside and rerun setup."
        }
        $allConfigured = $false
        if ($PSCmdlet.ShouldProcess($linkPath, "Link to $($entry.FullName)")) {
            New-Item -ItemType Directory -Path (Split-Path -Parent $linkPath) -Force | Out-Null
            if ($item) {
                Copy-Item -LiteralPath $linkPath -Destination "$linkPath.bak" -Force
                Remove-Item -LiteralPath $linkPath -Force
            }
            New-Item -ItemType SymbolicLink -Path $linkPath -Target $entry.FullName | Out-Null
        }
    }
    if ($allConfigured) { Write-Host 'pi work profile is already configured.' }
}

if (-not (Test-Path -LiteralPath $hotkeyScript -PathType Leaf)) {
    throw "Missing hotkey script: $hotkeyScript. Run setup from a complete dotfiles checkout."
}

# Add future setup steps below. Guard writes with ShouldProcess for -WhatIf.

# 1. Add ~/bin and the stable npm global bin to the user PATH, and pin the
#    npm global prefix to that stable location so it survives nvm version switches.
Add-UserPath -Directory (Join-Path $env:USERPROFILE 'bin')
$npmGlobalBin = Join-Path $env:APPDATA 'npm'
Add-UserPath -Directory $npmGlobalBin
$npmrcPath = Join-Path $env:USERPROFILE '.npmrc'
$npmrcLine = "prefix=$npmGlobalBin"
$npmrcContent = if (Test-Path -LiteralPath $npmrcPath) { Get-Content $npmrcPath -Raw } else { '' }
if ($npmrcContent -notmatch [regex]::Escape($npmrcLine)) {
    if ($PSCmdlet.ShouldProcess($npmrcPath, "Set npm prefix to $npmGlobalBin")) {
        Add-Content -LiteralPath $npmrcPath -Value $npmrcLine -Encoding UTF8 -NoNewline:$false
    }
} else {
    Write-Host 'npm prefix is already configured.'
}

# 3. Add Custom Keys.ahk to shell:startup for the current user.
Set-AutoHotkeyStartupShortcut -Script $hotkeyScript -StartupDirectory ([Environment]::GetFolderPath('Startup'))

# 4. Battery preferences for the current power plan. AC settings stay unchanged.
if ($PSCmdlet.ShouldProcess('Current Windows power plan', "Set battery hibernation to $hibernateTimeoutMinutes minutes and standby connectivity to $standbyConnectivityOnBattery")) {
    Invoke-PowerCfg -Arguments @('/change', 'hibernate-timeout-dc', "$hibernateTimeoutMinutes")
    Invoke-PowerCfg -Arguments @('/setdcvalueindex', 'SCHEME_CURRENT', 'SUB_NONE', 'CONNECTIVITYINSTANDBY', "$standbyConnectivityOnBattery")
    Invoke-PowerCfg -Arguments @('/setactive', 'SCHEME_CURRENT')
}

# 5. Skip Claude Code's folder trust prompt under the trusted folder.
Set-ClaudeFolderTrust -Folder $claudeTrustedFolder

# 6. Load the dotfiles PowerShell profile from pwsh's profile directory.
Set-PowerShellProfileStub -Source $powerShellProfile

# 7. Load the dotfiles git config from ~/.gitconfig.
Set-GitConfigStub -Source $gitConfig

# 7b. Load the dotfiles Git Bash profile from ~/.bashrc.
Set-BashrcStub -Source $gitBashProfile

# 8. Point Neovim's config directory at the checkout.
Set-NvimConfigJunction -Source $nvimConfig

# 9. Point Windows Terminal Preview's settings at the checkout.
Set-TerminalSettingsLink -Source $terminalSettings

# 10. Point atuin's config at the checkout.
Set-AtuinConfigLink -Source $atuinConfig

# 11. Point Zed's settings and keymap at the checkout.
Set-ZedConfigLinks -SourceDir $zedConfigDir

# 12. Apply the pi work profile from profiles/work/.pi.
Set-PiWorkProfile -SourceDir $piWorkProfile

# 13. Exclude the source folder from Defender real-time scanning.
Add-DefenderExclusion -Folder $defenderExcludedFolder

if (-not $WhatIfPreference) {
    Write-Host 'Windows setup complete. The hotkey script will run at your next sign-in.'
}
