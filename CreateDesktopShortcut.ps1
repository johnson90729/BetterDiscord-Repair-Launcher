$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $PSCommandPath
$launcher = Join-Path $scriptRoot "RunRepairAndLaunchHidden.vbs"

if (-not (Test-Path -LiteralPath $launcher -PathType Leaf)) {
    throw "Missing launcher: $launcher"
}

$desktop = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path $desktop "Discord BetterDiscord.lnk"
$startMenuPrograms = [Environment]::GetFolderPath("Programs")
$startMenuShortcutPath = Join-Path $startMenuPrograms "Discord BetterDiscord.lnk"

$wscript = Join-Path $env:WINDIR "System32\wscript.exe"

$discordRoot = Join-Path $env:LOCALAPPDATA "Discord"
$iconLocation = ""
if (Test-Path -LiteralPath $discordRoot -PathType Container) {
    $app = Get-ChildItem -LiteralPath $discordRoot -Directory -Filter "app-*" |
        Sort-Object Name -Descending |
        Select-Object -First 1

    if ($null -ne $app) {
        $discordExe = Join-Path $app.FullName "Discord.exe"
        if (Test-Path -LiteralPath $discordExe -PathType Leaf) {
            $iconLocation = "$discordExe,0"
        }
    }
}

function New-BetterDiscordShortcut {
    param([Parameter(Mandatory = $true)][string]$Path)

    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($Path)
    $shortcut.TargetPath = $wscript
    $shortcut.Arguments = "`"$launcher`""
    $shortcut.WorkingDirectory = $scriptRoot
    $shortcut.Description = "Check BetterDiscord, repair if needed, then launch Discord."
    if ($iconLocation) {
        $shortcut.IconLocation = $iconLocation
    }
    $shortcut.Save()
}

New-BetterDiscordShortcut -Path $shortcutPath
New-BetterDiscordShortcut -Path $startMenuShortcutPath

Write-Host "Created desktop shortcut:"
Write-Host $shortcutPath
Write-Host ""
Write-Host "Created Start Menu shortcut:"
Write-Host $startMenuShortcutPath
Write-Host ""
Write-Host "To pin it on Windows 11:"
Write-Host "1. Press the Windows key."
Write-Host "2. Search for Discord BetterDiscord."
Write-Host "3. Right-click it."
Write-Host "4. Choose Pin to taskbar."
