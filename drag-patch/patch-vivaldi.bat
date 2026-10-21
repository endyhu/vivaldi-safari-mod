@echo off
rem Double-click to patch Vivaldi's window.html with safari-drag.js (run again after
rem each Vivaldi update). unpatch-vivaldi.bat undoes it.
pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0patch-vivaldi.ps1" %*
echo.
echo Restart Vivaldi for the change to take effect.
pause
