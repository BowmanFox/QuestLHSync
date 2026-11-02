@echo off
rem Builds QuestLHSync 1.28-fix2's SteamVR driver with Visual Studio and puts it in place of the 1.28 one in
rem %LOCALAPPDATA%\QuestLHSync. Close SteamVR first. The 1.28 driver is kept in %LOCALAPPDATA%\QuestLHSync\backup-1.28,
rem and restore-1.28.cmd puts it back.
setlocal
cd /d "%~dp0"
tasklist /FI "IMAGENAME eq vrserver.exe" 2>nul | find /I "vrserver.exe" >nul && (
  echo SteamVR is running. Close SteamVR, then run this again.
  goto failed
)

set "DEST=%LOCALAPPDATA%\QuestLHSync\questlhsync\bin\win64"
set "BACKUP=%LOCALAPPDATA%\QuestLHSync\backup-1.28"
if not exist "%DEST%\driver_questlhsync.dll" (
  echo QuestLHSync isn't installed in %DEST%.
  goto failed
)

set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
set "VS="
for /f "usebackq delims=" %%i in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "VS=%%i"
if not defined VS (
  echo Visual Studio with C++ wasn't found.
  goto failed
)
echo Building the driver with %VS% ...
call "%VS%\VC\Auxiliary\Build\vcvars64.bat" >nul || goto failed
if not exist build mkdir build
if not exist out mkdir out
set MH=third_party\minhook
set OVR=third_party\openvr
cl /nologo /LD /O2 /EHsc /std:c++17 /MT /W3 /DNOMINMAX /DWIN32_LEAN_AND_MEAN /D_CRT_SECURE_NO_WARNINGS ^
  /I%OVR%\headers /I%MH%\include /Fobuild\ ^
  src\driver\driver_main.cpp src\driver\sync.cpp src\driver\net.cpp src\driver\gravity.cpp src\driver\relations.cpp ^
  %MH%\src\buffer.c %MH%\src\hook.c %MH%\src\trampoline.c %MH%\src\hde\hde64.c ^
  /Fe:out\driver_questlhsync.dll /link /NOLOGO ws2_32.lib iphlpapi.lib shell32.lib ole32.lib setupapi.lib hid.lib >build\log.txt 2>&1
if errorlevel 1 (
  type build\log.txt
  goto failed
)
if not exist out\driver_questlhsync.dll goto failed

if not exist "%BACKUP%\driver_questlhsync.dll" (
  if not exist "%BACKUP%" mkdir "%BACKUP%"
  copy /y "%DEST%\driver_questlhsync.dll" "%BACKUP%\" >nul || goto failed
)
copy /y out\driver_questlhsync.dll "%DEST%\" >nul || goto failed
echo.
echo Installed QuestLHSync 1.28-fix2. Start SteamVR.
pause
exit /b 0

:failed
echo.
echo Nothing was changed. Paste the text above into the chat with Claude.
pause
exit /b 1
