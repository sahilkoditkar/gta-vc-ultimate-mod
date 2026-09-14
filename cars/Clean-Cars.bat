@echo off
rem Only for publishing: cleans the archives here into publish\ and writes ..\cars.json
rem Usage: Clean-Cars.bat https://github.com/USER/REPO/releases/download/cars
cd /d "%~dp0"
if "%~1"=="" (
  echo Usage: Clean-Cars.bat https://github.com/USER/REPO/releases/download/TAG
  pause
  exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Clean-Cars.ps1" -ReleaseUrl "%~1"
echo.
pause
