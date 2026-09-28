@echo off
SETLOCAL EnableDelayedExpansion

cd /d "%~dp0"
set PATH=%PATH%;%VSAPPIDDIR%\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\Git\cmd

rem ---- cuphwi version scheme: <tag>_<commit YYYYMMDD>[-female_Emanim] ----
if "!VERSION!"=="" (
rem Fixed project prefix (cuphwi BN base)
set "VERSION_TAG=B.N."
rem Commit date of HEAD (YYYYMMDD)
set "COMMIT_DATE="
for /F "tokens=*" %%i in ('git log -1 --date^=format:%%Y%%m%%d --format^=%%cd 2^>nul') do set "COMMIT_DATE=%%i"
if "!COMMIT_DATE!"=="" set "COMMIT_DATE=00000000"
rem Dirty worktree marker
git diff --quiet >nul 2>&1
if errorlevel 1 (
set "SUFFIX=-female_Emanim"
) else (
set "SUFFIX="
)
set "VERSION=!VERSION_TAG!_!COMMIT_DATE!!SUFFIX!"
)
if "!VERSION!"=="" (
set VERSION=Please install `git` to generate VERSION, or set the variable manually
)
if "%BUILD_TIMESTAMP%"=="" (
for /F "tokens=*" %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd-HHmm"') do set BUILD_TIMESTAMP=%%i
)
set NEED_REGEN=0
findstr /c:"#define VERSION \"!VERSION!\"" ..\src\version.h > NUL 2> NUL
if %ERRORLEVEL% NEQ 0 set NEED_REGEN=1
findstr /c:"#define BUILD_TIMESTAMP \"%BUILD_TIMESTAMP%\"" ..\src\version.h > NUL 2> NUL
if %ERRORLEVEL% NEQ 0 set NEED_REGEN=1
if %NEED_REGEN% NEQ 0 (
echo Generating "version.h"...
echo VERSION defined as "!VERSION!"
echo BUILD_TIMESTAMP defined as "%BUILD_TIMESTAMP%"
>..\src\version.h echo // NOLINT(cata-header-guard)
>>..\src\version.h echo #define VERSION "!VERSION!"
>>..\src\version.h echo #define BUILD_TIMESTAMP "%BUILD_TIMESTAMP%"
)

if /I "%~1"=="shaders" (
powershell -NoProfile -ExecutionPolicy Bypass -File build-scripts\generate-shaders.ps1 -VcpkgTriplet "%~2"
if ERRORLEVEL 1 exit /B %ERRORLEVEL%
)
