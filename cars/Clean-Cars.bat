@echo off
rem Cleans the car archives in this folder in place (data files only, no exe).
rem Optional argument: a GitHub release URL -> also writes ..\cars.json
rem   Clean-Cars.bat
rem   Clean-Cars.bat https://github.com/USER/REPO/releases/download/cars
cd /d "%~dp0"
if "%~1"=="" (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Clean-Cars.ps1"
) else (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Clean-Cars.ps1" -ReleaseUrl "%~1"
)
echo.
pause
