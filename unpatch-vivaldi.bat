@echo off
rem Double-click to remove safari-drag.js from Vivaldi's window.html, and the scheduled
rem task that re-applies it if one was registered.
pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\patch-vivaldi.ps1" -Remove -Unregister %*
echo.
echo Restart Vivaldi for the change to take effect.
pause
