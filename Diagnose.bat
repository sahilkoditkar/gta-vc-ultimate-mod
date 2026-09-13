@echo off
rem Game does not start after installing? This finds out which part is the problem.
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" -Diagnose %*
echo.
pause
