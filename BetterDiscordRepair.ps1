param(
    [ValidateSet("stable", "ptb", "canary")]
    [string]$Channel = "stable",

    [string]$DiscordRoot = "",
    [string]$AssetsRoot = "",

    [switch]$CloseDiscord,
    [switch]$Launch,
    [switch]$Restart,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$channels = @{
    stable = @{ Root = "Discord"; Process = "Discord"; Exe = "Discord.exe" }
    ptb    = @{ Root = "DiscordPTB"; Process = "DiscordPTB"; Exe = "DiscordPTB.exe" }
    canary = @{ Root = "DiscordCanary"; Process = "DiscordCanary"; Exe = "DiscordCanary.exe" }
}

function Get-VersionParts {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Prefix
    )

    if (-not $Name.StartsWith($Prefix, [StringComparison]::OrdinalIgnoreCase)) {
        return $null
    }

    $suffix = $Name.Substring($Prefix.Length)
    if ($suffix -notmatch '^\d+([._-]\d+)*$') {
        return $null
    }

    return @($suffix -split '[._-]' | ForEach-Object { [int]$_ })
}

function Compare-VersionParts {
    param(
        [int[]]$Left,
        [int[]]$Right
    )

    $count = [Math]::Max($Left.Count, $Right.Count)
    for ($index = 0; $index -lt $count; $index++) {
        $a = if ($index -lt $Left.Count) { $Left[$index] } else { 0 }
        $b = if ($index -lt $Right.Count) { $Right[$index] } else { 0 }

        if ($a -lt $b) { return -1 }
        if ($a -gt $b) { return 1 }
    }

    return 0
}

function Get-LatestVersionedDirectory {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Prefix,
        [string]$RequiredChild = ""
    )

    if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
        return $null
    }

    $best = $null
    [int[]]$bestVersion = @()

    foreach ($directory in Get-ChildItem -LiteralPath $Root -Directory) {
        $version = Get-VersionParts -Name $directory.Name -Prefix $Prefix
        if ($null -eq $version) {
            continue
        }

        if ($RequiredChild) {
            $child = Join-Path $directory.FullName $RequiredChild
            if (-not (Test-Path -LiteralPath $child -PathType Container)) {
                continue
            }
        }

        if ($null -eq $best -or (Compare-VersionParts -Left $version -Right $bestVersion) -gt 0) {
            $best = $directory
            $bestVersion = $version
        }
    }

    return $best
}

function Get-AssetsRoot {
    param([string]$ExplicitRoot)

    $scriptRoot = Split-Path -Parent $PSCommandPath
    $candidates = @()

    if ($ExplicitRoot) {
        $candidates += $ExplicitRoot
    } else {
        $candidates += $scriptRoot
        $candidates += (Split-Path -Parent $scriptRoot)
        $candidates += (Get-Location).Path
        $candidates += (Split-Path -Parent (Get-Location).Path)
    }

    foreach ($candidate in $candidates) {
        if (-not $candidate) {
            continue
        }

        $asar = Join-Path $candidate "betterDiscord_ASAR\betterdiscord.asar"
        $index = Join-Path $candidate "index_JSON\index_replacer.js"
        if ((Test-Path -LiteralPath $asar -PathType Leaf) -and (Test-Path -LiteralPath $index -PathType Leaf)) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    throw "Could not find betterDiscord_ASAR\betterdiscord.asar and index_JSON\index_replacer.js."
}

function Test-BetterDiscordInjection {
    param(
        [Parameter(Mandatory = $true)][string]$CoreDir,
        [string]$SourceAsar = "",
        [string]$SourceIndex = ""
    )

    $asar = Join-Path $CoreDir "betterdiscord.asar"
    $index = Join-Path $CoreDir "index.js"

    if (-not (Test-Path -LiteralPath $asar -PathType Leaf)) {
        return @{ Installed = $false; Reason = "betterdiscord.asar is missing" }
    }

    if (-not (Test-Path -LiteralPath $index -PathType Leaf)) {
        return @{ Installed = $false; Reason = "index.js is missing" }
    }

    $content = Get-Content -LiteralPath $index -Raw
    if ($content -notlike "*betterdiscord.asar*") {
        return @{ Installed = $false; Reason = "index.js does not load BetterDiscord" }
    }

    if ($SourceAsar -and (Test-Path -LiteralPath $SourceAsar -PathType Leaf)) {
        $sourceAsarHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $SourceAsar).Hash
        $targetAsarHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $asar).Hash
        if ($sourceAsarHash -ne $targetAsarHash) {
            return @{ Installed = $false; Reason = "betterdiscord.asar differs from bundled payload" }
        }
    }

    if ($SourceIndex -and (Test-Path -LiteralPath $SourceIndex -PathType Leaf)) {
        $sourceIndexHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $SourceIndex).Hash
        $targetIndexHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $index).Hash
        if ($sourceIndexHash -ne $targetIndexHash) {
            return @{ Installed = $false; Reason = "index.js differs from bundled replacement" }
        }
    }

    return @{ Installed = $true; Reason = "BetterDiscord is already injected" }
}

function Get-NextBackupPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    for ($index = 0; $index -lt 1000; $index++) {
        $backup = if ($index -eq 0) { "$Path.bd-backup" } else { "$Path.bd-backup.$index" }
        if (-not (Test-Path -LiteralPath $backup)) {
            return $backup
        }
    }

    return "$Path.bd-backup-last"
}

$channelInfo = $channels[$Channel]

if (-not $DiscordRoot) {
    if (-not $env:LOCALAPPDATA) {
        throw "LOCALAPPDATA is not set. Pass -DiscordRoot manually."
    }
    $DiscordRoot = Join-Path $env:LOCALAPPDATA $channelInfo.Root
}

$AssetsRoot = Get-AssetsRoot -ExplicitRoot $AssetsRoot
$appDir = Get-LatestVersionedDirectory -Root $DiscordRoot -Prefix "app-"
if ($null -eq $appDir) {
    throw "Could not find any app-* directory under $DiscordRoot."
}

$modulesDir = Join-Path $appDir.FullName "modules"
$coreContainer = Get-LatestVersionedDirectory -Root $modulesDir -Prefix "discord_desktop_core-" -RequiredChild "discord_desktop_core"
if ($null -eq $coreContainer) {
    throw "Could not find discord_desktop_core-* under $modulesDir."
}

$coreDir = Join-Path $coreContainer.FullName "discord_desktop_core"
$discordExe = Join-Path $appDir.FullName $channelInfo.Exe
$sourceAsar = Join-Path $AssetsRoot "betterDiscord_ASAR\betterdiscord.asar"
$sourceIndex = Join-Path $AssetsRoot "index_JSON\index_replacer.js"
$didRepair = $false

Write-Host "Discord root: $DiscordRoot"
Write-Host "App version:  $($appDir.Name)"
Write-Host "Core path:    $coreDir"

$status = Test-BetterDiscordInjection -CoreDir $coreDir -SourceAsar $sourceAsar -SourceIndex $sourceIndex
if ($status.Installed -and -not $Force) {
    Write-Host "OK: $($status.Reason)"
} else {
    $processes = @(Get-Process -Name $channelInfo.Process -ErrorAction SilentlyContinue)
    if ($processes.Count -gt 0) {
        if (-not $CloseDiscord) {
            Write-Error "Discord is running. Close it and rerun, or pass -CloseDiscord."
            exit 2
        }

        $processes | Stop-Process -Force
        Start-Sleep -Milliseconds 1500
    }

    $targetAsar = Join-Path $coreDir "betterdiscord.asar"
    $targetIndex = Join-Path $coreDir "index.js"

    if ((Test-Path -LiteralPath $targetIndex -PathType Leaf) -and ((Get-Content -LiteralPath $targetIndex -Raw) -notlike "*betterdiscord.asar*")) {
        Copy-Item -LiteralPath $targetIndex -Destination (Get-NextBackupPath -Path $targetIndex)
    }

    Copy-Item -LiteralPath $sourceAsar -Destination $targetAsar -Force
    Copy-Item -LiteralPath $sourceIndex -Destination $targetIndex -Force

    $after = Test-BetterDiscordInjection -CoreDir $coreDir -SourceAsar $sourceAsar -SourceIndex $sourceIndex
    if (-not $after.Installed) {
        throw "Repair finished, but verification failed: $($after.Reason)"
    }

    $didRepair = $true
    if ($Force) {
        Write-Host "Changed: BetterDiscord injection refreshed."
    } else {
        Write-Host "Changed: BetterDiscord injection repaired."
    }
}

if ($Launch) {
    $running = @(Get-Process -Name $channelInfo.Process -ErrorAction SilentlyContinue)
    if ($running.Count -gt 0 -and $Restart -and $didRepair) {
        $running | Stop-Process -Force
        Start-Sleep -Milliseconds 1500
        Start-Process -FilePath $discordExe -WorkingDirectory (Split-Path -Parent $discordExe)
        Write-Host "Discord restarted."
    } elseif ($running.Count -gt 0) {
        Write-Host "Discord is already running."
    } elseif (Test-Path -LiteralPath $discordExe -PathType Leaf) {
        Start-Process -FilePath $discordExe -WorkingDirectory (Split-Path -Parent $discordExe)
        Write-Host "Discord launched."
    } else {
        Write-Error "Could not launch Discord from $discordExe."
        exit 3
    }
}
