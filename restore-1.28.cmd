@echo off
rem Puts the official QuestLHSync 1.28 driver back (the copy build-and-install.cmd kept). Close SteamVR first.
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
copy /y "%BACKUP%\driver_questlhsync.dll" "%DEST%\" >nul || goto failed
echo Restored QuestLHSync 1.28. Start SteamVR.
pause
exit /b 0

:failed
pause
exit /b 1
