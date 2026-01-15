@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "TARGET=%~1"
set "CFG=%~2"

set "LOG=%TEMP%\postbuild_rename_exe.log"
echo ==== %DATE% %TIME% ====>>"%LOG%"

call :log START TARGET="%TARGET%" CFG="%CFG%"

if "%CFG%"=="" set "CFG=%Configuration%"
if "%CFG%"=="" set "CFG=%ConfigurationName%"
call :log RESOLVED CFG="%CFG%"

if /I not "%CFG%"=="Release" (
  call :log Skipping rename (CFG=%CFG%)
  exit /b 0
)

if not exist "%TARGET%" (
  call :log Target not found: "%TARGET%"
  exit /b 1
)

rem repo root: git toplevel if possible, fallback to script parent
set "ROOT="
for /f "delims=" %%i in ('git rev-parse --show-toplevel 2^>nul') do set "ROOT=%%i"
if "%ROOT%"=="" set "ROOT=%~dp0.."
call :log ROOT="%ROOT%"

rem get last commit date (YYYYMMDD) from HEAD
pushd "%ROOT%" >nul
if errorlevel 1 (
  call :log pushd failed ROOT="%ROOT%"
  exit /b 1
)

set "CDATE="
for /f "delims=" %%i in ('git log -1 --date^=format:%%Y%%m%%d --format^=%%cd 2^>nul') do set "CDATE=%%i"
popd >nul

if "%CDATE%"=="" set "CDATE=00000000"
call :log CDATE="%CDATE%"

for %%F in ("%TARGET%") do set "TDIR=%%~dpF"
set "DEST=%TDIR%Cataclysm-cuphwi.%CDATE%.exe"
call :log DEST="%DEST%"

if /I "%TARGET%"=="%DEST%" (
  call :log Already named
  exit /b 0
)

if exist "%DEST%" (
  del /f /q "%DEST%"
  if errorlevel 1 (
    call :log Failed to delete existing DEST
    exit /b 1
  )
)

move /Y "%TARGET%" "%DEST%"
if errorlevel 1 (
  call :log MOVE FAILED (file locked or permission)
  exit /b 1
)

if not exist "%DEST%" (
  call :log MOVE claimed success but DEST missing
  exit /b 1
)

call :log Renamed to "%DEST%"
exit /b 0

:log
echo [postbuild_rename_exe] %*
echo [postbuild_rename_exe] %*>>"%LOG%"
exit /b 0
