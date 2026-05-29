@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem ---- Generate lua bindings (same as upstream style: pushd/popd) ----
rem Use %~dp0 (this script's own directory) so it works regardless of the
rem caller's current working directory.
pushd "%~dp0..\src\lua" >nul
echo Generating lua bindings
lua generate_bindings.lua
popd >nul
echo Done

rem ---- Version tag (prefer git tag; fallback to C.0) ----
set "VERSION_TAG="
for /F "usebackq tokens=* delims=" %%i in (`git describe --tags --abbrev^=0 --match "[A-Za-z0-9]*.[0-9A-Za-z]*" 2^>nul`) do set "VERSION_TAG=%%i"
if "!VERSION_TAG!"=="" set "VERSION_TAG=C.0"

rem ---- Commit date (YYYYMMDD; fallback 00000000) ----
set "COMMIT_DATE="
for /F "usebackq tokens=* delims=" %%i in (`git log -1 --date^=format:%%Y%%m%%d --format^=%%cd 2^>nul`) do set "COMMIT_DATE=%%i"
if "!COMMIT_DATE!"=="" set "COMMIT_DATE=00000000"

rem ---- Dirty check ----
git diff --quiet >nul 2>&1
if errorlevel 1 (
  set "SUFFIX=-female_Emanim"
) else (
  set "SUFFIX="
)

set "VERSION=!VERSION_TAG!_!COMMIT_DATE!!SUFFIX!"
echo VERSION defined as !VERSION!

rem ---- Write version.h (pragma once) ----
set "VERSION_H=%~dp0..\src\version.h"
(
  echo #pragma once
  echo #define VERSION "!VERSION!"
) > "!VERSION_H!"
