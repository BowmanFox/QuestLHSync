@echo off
rem Builds QuestLHSync 1.28-fix3 with Visual Studio, the SteamVR driver and the dashboard app (QuestLHSync.exe), and
rem puts them in place of the installed ones in %LOCALAPPDATA%\QuestLHSync. Close SteamVR first. The official 1.28 files
rem are kept in %LOCALAPPDATA%\QuestLHSync\backup-1.28, and restore-1.28.cmd puts them back.
rem   build-and-install.cmd build    only builds them into out\ (SteamVR may be running)
setlocal
cd /d "%~dp0"
set "DEST=%LOCALAPPDATA%\QuestLHSync\questlhsync\bin\win64"
set "BACKUP=%LOCALAPPDATA%\QuestLHSync\backup-1.28"
set "ONLY_BUILD="
if /i "%~1"=="build" set "ONLY_BUILD=1"
if defined ONLY_BUILD goto build

tasklist /FI "IMAGENAME eq vrserver.exe" 2>nul | find /I "vrserver.exe" >nul && (
  echo SteamVR is running. Close SteamVR, then run this again.
  goto failed
)
if not exist "%DEST%\driver_questlhsync.dll" (
  echo QuestLHSync isn't installed in %DEST%.
  goto failed
)

:build
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
set "VS="
for /f "usebackq delims=" %%i in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "VS=%%i"
if not defined VS (
  echo Visual Studio with C++ wasn't found.
  goto failed
)
echo Building the driver and the dashboard app with %VS% ...
call "%VS%\VC\Auxiliary\Build\vcvars64.bat" >nul || goto failed
if not exist build\driver mkdir build\driver
if not exist build\overlay mkdir build\overlay
if not exist out mkdir out
set MH=third_party\minhook
set OVR=third_party\openvr
cl /nologo /LD /O2 /EHsc /std:c++17 /MT /W3 /DNOMINMAX /DWIN32_LEAN_AND_MEAN /D_CRT_SECURE_NO_WARNINGS ^
  /I%OVR%\headers /I%MH%\include /Fobuild\driver\ ^
  src\driver\driver_main.cpp src\driver\sync.cpp src\driver\net.cpp src\driver\gravity.cpp src\driver\relations.cpp ^
  %MH%\src\buffer.c %MH%\src\hook.c %MH%\src\trampoline.c %MH%\src\hde\hde64.c ^
  /Fe:out\driver_questlhsync.dll /link /NOLOGO ws2_32.lib iphlpapi.lib shell32.lib ole32.lib setupapi.lib hid.lib >build\log.txt 2>&1
if errorlevel 1 (
  type build\log.txt
  goto failed
)
cl /nologo /utf-8 /O2 /EHsc /std:c++17 /MT /W3 /DNOMINMAX /DWIN32_LEAN_AND_MEAN /DUNICODE /D_UNICODE /D_CRT_SECURE_NO_WARNINGS ^
  /I%OVR%\headers /Fobuild\overlay\ src\overlay\overlay_main.cpp ^
  /Fe:out\QuestLHSync.exe /link /NOLOGO /SUBSYSTEM:WINDOWS %OVR%\lib\win64\openvr_api.lib gdi32.lib user32.lib shell32.lib d3d11.lib dxgi.lib >build\log-overlay.txt 2>&1
if errorlevel 1 (
  type build\log-overlay.txt
  goto failed
)
if not exist out\driver_questlhsync.dll goto failed
if not exist out\QuestLHSync.exe goto failed
del out\driver_questlhsync.exp out\driver_questlhsync.lib 2>nul
rem dashboard previews, no VR: out\preview-*.png
copy /y %OVR%\bin\win64\openvr_api.dll out\ >nul
start "" /wait out\QuestLHSync.exe --preview out\preview-locked.png locked
start "" /wait out\QuestLHSync.exe --preview out\preview-trackersoff.png trackersoff
if defined ONLY_BUILD (
  echo Built out\driver_questlhsync.dll and out\QuestLHSync.exe, nothing installed.
  exit /b 0
)

rem the dashboard app quits a moment after SteamVR does
set /a WAITED=0
:dashboard
tasklist /FI "IMAGENAME eq QuestLHSync.exe" 2>nul | find /I "QuestLHSync.exe" >nul || goto install
set /a WAITED+=1
if %WAITED% gtr 10 (
  echo QuestLHSync.exe is still running. End it in Task Manager, then run this again.
  goto failed
)
ping -n 2 127.0.0.1 >nul
goto dashboard

:install
if not exist "%BACKUP%" mkdir "%BACKUP%"
if not exist "%BACKUP%\driver_questlhsync.dll" (
  copy /y "%DEST%\driver_questlhsync.dll" "%BACKUP%\" >nul || goto failed
)
if not exist "%BACKUP%\QuestLHSync.exe" if exist "%DEST%\QuestLHSync.exe" (
  copy /y "%DEST%\QuestLHSync.exe" "%BACKUP%\" >nul || goto failed
)
copy /y out\QuestLHSync.exe "%DEST%\" >nul || goto failed
if not exist "%DEST%\openvr_api.dll" copy /y %OVR%\bin\win64\openvr_api.dll "%DEST%\" >nul
copy /y out\driver_questlhsync.dll "%DEST%\" >nul || (
  echo The dashboard app was updated but the driver wasn't. Run this again with SteamVR closed.
  pause
  exit /b 1
)
echo.
echo Installed QuestLHSync 1.28-fix3. Start SteamVR.
pause
exit /b 0

:failed
echo.
echo Nothing was changed. Paste the text above into the chat with Claude.
pause
exit /b 1
