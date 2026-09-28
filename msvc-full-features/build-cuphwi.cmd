@echo off
rem Build Cataclysm-cuphwi (Release|x64) at Below Normal CPU priority.
rem -lowPriority makes msbuild nodes and child cl.exe/link.exe inherit low priority.
rem Extra args are passed through, e.g.: build-cuphwi.cmd -p:Configuration=Debug
"C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\amd64\MSBuild.exe" "%~dp0Cataclysm-vcpkg-static.sln" -lowPriority -m -v:m -p:Configuration=Release -p:Platform=x64 %*
