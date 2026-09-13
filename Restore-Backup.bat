@echo off
rem Puts the game back exactly as it was before the last install run.
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" -Restore %*
echo.
pause
