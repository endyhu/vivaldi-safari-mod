@echo off
rem Double-click to patch Vivaldi's window.html with safari-drag.js (run again after
rem each Vivaldi update). Pass -Remove to undo: patch-vivaldi.bat -Remove
pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\patch-vivaldi.ps1" %*
echo.
echo Restart Vivaldi for the change to take effect.
pause
