@echo off
setlocal
set SRC=%~dp0..
set DST=C:\Users\forsu\Projects\kalimat

echo Close Cursor/IDE before continuing.
pause

if exist "%DST%" (
  echo Removing existing kalimat folder...
  rmdir /s /q "%DST%"
)

echo Renaming project folder...
move "%SRC%" "%DST%"
if errorlevel 1 (
  echo Rename failed. The folder may still be in use.
  exit /b 1
)

echo.
echo Renamed to: %DST%
echo Open %DST% in Cursor and run: flutter pub get
pause
