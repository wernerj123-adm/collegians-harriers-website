@echo off
setlocal
cd /d "%~dp0"

echo Collegians Harriers Staging Package Builder
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\build-deployment-package.ps1" -Channel staging
set "build_exit=%ERRORLEVEL%"

echo.
if not "%build_exit%"=="0" echo The package was not created. Review the message above.
pause
exit /b %build_exit%
