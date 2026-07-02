@echo off
cd /d %~dp0..
echo Building Flutter web...
call flutter build web --release
if errorlevel 1 exit /b 1

if exist server\public rmdir /s /q server\public
xcopy /E /I /Y build\web server\public >nul

echo.
echo Unified app ready. Start with:
echo   cd server
echo   npm start
echo.
echo Then open: http://localhost:3000
echo.
echo For public internet deploy, use Render.com with the Dockerfile in project root.
