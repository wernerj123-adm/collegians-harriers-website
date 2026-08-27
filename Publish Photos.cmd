@echo off
setlocal
cd /d "%~dp0"

echo Collegians Harriers Photo Publisher
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\publish-photos.ps1"
set "publish_exit=%ERRORLEVEL%"

echo.
if not "%publish_exit%"=="0" echo The publisher stopped before completing. Review the message above.
pause
exit /b %publish_exit%
