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

Setup
Download betterdiscord.asar from the official BetterDiscord release page and place it here:
betterDiscord_ASAR\betterdiscord.asar
Keep the folder structure unchanged.
Usage
Normal launcher with visible console:
RunRepairAndLaunch.cmd
Hidden launcher, recommended for daily use:
RunRepairAndLaunchHidden.vbs
Create desktop and Start Menu shortcuts:
CreateDesktopShortcut.cmd
Then search for Discord BetterDiscord in the Start Menu and pin it to the taskbar.
Force Refresh
If BetterDiscord does not appear, or after replacing betterdiscord.asar, run:
ForceRefresh.cmd
How It Works
The launcher:
Finds the latest Discord version folder
Finds the latest Discord desktop core folder
Checks whether BetterDiscord is already injected
Compares the bundled files with the injected files
Does nothing if everything matches
Repairs only when files are missing or different
Launches or restarts Discord when needed
Uninstall
Delete this tool folder.
To manually remove the injection from Discord:
Close Discord
Open the latest Discord core folder
Delete betterdiscord.asar
Restore index.js.bd-backup back to index.js if the backup exists
You can also use the official BetterDiscord installer to uninstall or repair BetterDiscord.
Notes
This tool does not include any auto-updater. To update BetterDiscord, manually replace:
betterDiscord_ASAR\betterdiscord.asar
Then run ForceRefresh.cmd.
For public GitHub releases, consider not committing betterdiscord.asar directly. Instead, ask users to download it from the official BetterDiscord release page.
