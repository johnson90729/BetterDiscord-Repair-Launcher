@echo off
set "SCRIPT_DIR=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%BetterDiscordRepair.ps1" -CloseDiscord -Force
pause
