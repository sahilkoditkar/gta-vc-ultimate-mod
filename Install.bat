@echo off
rem Double-click this file. It runs install.ps1 with the execution policy relaxed
rem for this one process only (nothing is changed system-wide).
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
echo.
pause
