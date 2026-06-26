# BetterDiscord Repair Launcher

A small portable Windows launcher that checks and repairs BetterDiscord after Discord updates.

Discord updates often create a new `app-*` folder, which can remove the BetterDiscord injection from the latest Discord desktop core. This tool checks the newest Discord core before launching Discord and only repairs when needed.

> Not affiliated with Discord or BetterDiscord. Use at your own risk.

## Features

- Automatically finds stable Discord in `%LOCALAPPDATA%\Discord`
- Detects the newest `app-*` folder
- Detects the newest `discord_desktop_core-*` folder
- Checks whether `betterdiscord.asar` is installed
- Checks whether `index.js` loads BetterDiscord
- Compares file hashes to avoid unnecessary rewrites
- Repairs only when BetterDiscord is missing or outdated
- Can launch Discord without showing a command prompt window
- Does not run in the background
- Does not auto-download files from GitHub

## Files

```text
BetterDiscordRepair.ps1
RunRepair.cmd
RunRepairAndLaunch.cmd
RunRepairAndLaunchHidden.vbs
CreateDesktopShortcut.cmd
CreateDesktopShortcut.ps1
ForceRefresh.cmd
betterDiscord_ASAR/
  betterdiscord.asar
index_JSON/
  index_replacer.js
