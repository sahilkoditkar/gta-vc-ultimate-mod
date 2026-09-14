@echo off
rem Hashes the car archives in cars\ and writes cars.json for a GitHub release.
rem Usage: Publish-Cars.bat https://github.com/USER/REPO/releases/download/cars
cd /d "%~dp0"
if "%~1"=="" (
  echo Usage: Publish-Cars.bat https://github.com/USER/REPO/releases/download/TAG
  pause
  exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" -MakeCarsManifest -ReleaseUrl "%~1"
echo.
pause
