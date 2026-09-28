@echo off
rem Build Cataclysm-cuphwi (Release|x64) at Below Normal CPU priority.
rem Start MSBuild BelowNormal; -lowPriority also lowers worker nodes and child tools.
rem Extra args are passed through, e.g.: build-cuphwi.cmd -p:Configuration=Debug
start "" /b /wait /belownormal "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\amd64\MSBuild.exe" "%~dp0Cataclysm-vcpkg-static.sln" -lowPriority -m:2 -v:m -p:Configuration=Release -p:Platform=x64 -p:MultiProcessorCompilation=false %*
