@echo off
rem Writes clean copies (data files only, no exe) of the archives here into clean\ and updates ..\cars.json
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Clean-Cars.ps1"
echo.
pause
