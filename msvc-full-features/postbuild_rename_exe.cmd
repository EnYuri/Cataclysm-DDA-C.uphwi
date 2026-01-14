@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem %1 = built exe full path (TargetPath)
rem %2 = configuration name (Debug/Release)
set "TARGET=%~1"
set "CFG=%~2"

if "%CFG%"=="" set "CFG=%Configuration%"
if "%CFG%"=="" set "CFG=%ConfigurationName%"

if /I not "%CFG%"=="Release" (
  echo Skipping rename (CFG=%CFG%)
  exit /b 0
)

if not exist "%TARGET%" (
  echo Target not found: "%TARGET%"
  exit /b 1
)

rem repo root is parent of this script's folder (msvc-full-features\..)
set "ROOT=%~dp0.."

rem get last commit date (YYYYMMDD)
pushd "%ROOT%" >nul
for /f "delims=" %%i in ('git log -1 --date^=format:%%Y%%m%%d --format^=%%cd 2^>nul') do set "CDATE=%%i"
popd >nul
if "%CDATE%"=="" set "CDATE=00000000"

rem destination in same folder as target
for %%F in ("%TARGET%") do set "TDIR=%%~dpF"
set "DEST=%TDIR%cataclysm-C-%CDATE%.exe"

if /I "%TARGET%"=="%DEST%" (
  echo Already named: "%DEST%"
  exit /b 0
)

if exist "%DEST%" del /f /q "%DEST%"

move /Y "%TARGET%" "%DEST%" >nul
echo Renamed to "%DEST%"
exit /b 0
