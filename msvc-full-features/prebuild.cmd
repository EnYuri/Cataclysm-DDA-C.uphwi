@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem
pushd ..\src\lua
echo Generating lua bindings
lua generate_bindings.lua
popd
echo Done

rem --- Version string: .C_YYYYMMDD + -cuphwi if dirty ---
set VERSION_TAG=.C

for /F "tokens=*" %%i in ('git log -1 --date^=format:%%Y%%m%%d --format^=%%cd 2^>nul') do set COMMIT_DATE=%%i
if "%COMMIT_DATE%"=="" set COMMIT_DATE=00000000

git diff --quiet >nul 2>&1
if errorlevel 1 (
  set SUFFIX=-cuphwi
) else (
  set SUFFIX=
)

set VERSION=%VERSION_TAG%_%COMMIT_DATE%%SUFFIX%
echo VERSION defined as %VERSION%

rem
set VERSION_H=..\src\version.h
(
  echo #pragma once
  echo #define VERSION "%VERSION%"
) > "%VERSION_H%"
