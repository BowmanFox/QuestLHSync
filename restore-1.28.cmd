@echo off
rem Puts the official QuestLHSync 1.28 driver and dashboard app back (the copies build-and-install.cmd kept). Close
rem SteamVR first.
setlocal
tasklist /FI "IMAGENAME eq vrserver.exe" 2>nul | find /I "vrserver.exe" >nul && (
  echo SteamVR is running. Close SteamVR, then run this again.
  goto failed
)
set "DEST=%LOCALAPPDATA%\QuestLHSync\questlhsync\bin\win64"
set "BACKUP=%LOCALAPPDATA%\QuestLHSync\backup-1.28"
if not exist "%BACKUP%\driver_questlhsync.dll" (
  echo No saved 1.28 driver in %BACKUP%. Run QuestLHSync-steamvr-installer.exe and click Reinstall instead.
  goto failed
)
rem the dashboard app quits a moment after SteamVR does
set /a WAITED=0
:dashboard
tasklist /FI "IMAGENAME eq QuestLHSync.exe" 2>nul | find /I "QuestLHSync.exe" >nul || goto restore
set /a WAITED+=1
if %WAITED% gtr 10 (
  echo QuestLHSync.exe is still running. End it in Task Manager, then run this again.
  goto failed
)
ping -n 2 127.0.0.1 >nul
goto dashboard

:restore
if exist "%BACKUP%\QuestLHSync.exe" copy /y "%BACKUP%\QuestLHSync.exe" "%DEST%\" >nul || goto failed
copy /y "%BACKUP%\driver_questlhsync.dll" "%DEST%\" >nul || goto failed
echo Restored QuestLHSync 1.28. Start SteamVR.
pause
exit /b 0

:failed
pause
exit /b 1
