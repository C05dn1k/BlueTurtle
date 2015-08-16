@ECHO OFF
REM.-- Prepare the Command Processor
SETLOCAL ENABLEEXTENSIONS
SETLOCAL ENABLEDELAYEDEXPANSION

REM.-- Version History --
SET "version=1.00"      &rem 15/AUG/2015 BlueTurtle  Initial version
SET "version=%version: =%"

REM.-- Set the window title, color, and size 
SET "title=%~n0 - %version%"
TITLE %title%
COLOR 1F
MODE CON: COLS=100 LINES=50

REM. -- Get drive letter for the epix
SET "rootDir=NOTFOUND"
SET "epixVolumeSerialNumber=000001A1"
FOR /F "tokens=1,2 delims= " %%A IN ('WMIC logicaldisk get DeviceID^,VolumeSerialNumber^') DO (IF %%B EQU %epixVolumeSerialNumber% SET "rootDir=%%A\")
IF "%rootDir%" EQU "NOTFOUND" (ECHO.The epix does not seem to be properly mounted as a mass storage volume. Bailing cowardly.&&PAUSE&&GOTO:EOF)

SET "garminDir=%rootDir%Garmin\"
SET "fileList=,%garminDir%Locations\Locations.fit,%garminDir%Records\Records.fit,%garminDir%Settings\Settings.fit,%garminDir%Sports\*.fit,%garminDir%MltSport\*.fit,%garminDir%Totals\Totals.fit,"

SET ""restoreFrom_choice="
call:getBkpDirList restoreFrom_choice

SET "restoreFrom="
call:getNextInList restoreFrom "!restoreFrom_choice!"

:menuLoop
ECHO.
ECHO.====== BlueTurtle ========== Tool for Saving and Restoring epix Settings ===== %DATE% ======
ECHO.
ECHO.                               ************* Status **************
ECHO.
ECHO.                               **** epix mounted as drive %rootDir% ****
ECHO.
ECHO.                               ***********************************
ECHO.
FOR /F "tokens=1,2,* delims=_ " %%A IN ('"FINDSTR /B /C:":menu_" "%~f0""') DO ECHO.    %%B  %%C
SET choice=
ECHO.&SET /P choice=Make a choice or hit ENTER to quit: ||(
    GOTO:EOF
)
ECHO.&CALL:menu_%choice%
GOTO:menuLoop

:menu_== Main Menu ==============================================================================

:menu_
:menu_SX   Save Settings

SET "saveToDir=MM_DD_HHMMSS"
CALL:getTimeStamp saveToDir
SET "saveToDir"="%~dp0!saveToDir!"

IF EXIST %saveToDir%nul RD /S %saveToDir%
MD %saveToDir%

ECHO.Saving settings to %saveToDir%
FOR /L %%C IN (1,1,6) DO (
    CALL:getNextInList aFile "!fileList!"
	xcopy "!aFile!" "%saveToDir%" /V /F
)
CALL:pauseAndClear
GOTO:EOF

:menu_RX   Restore Settings

SET "restoreFromDir=%~dp0!restoreFrom!\"
SET "restoreToDir=!garminDir!NewFiles\"

IF EXIST %restoreToDir%*.fit DEL /Q "%restoreToDir%*.fit"

ECHO.
ECHO.Restoring settings from %restoreFromDir%
ECHO.
xcopy "%restoreFromDir%*.fit" "%restoreToDir%" /V /F
call:pauseAndClear
GOTO:EOF

:menu_
:menu_== Options ================================================================================
:menu_

:menu_1   Backup Directory to be Restored : '!restoreFrom!' [!restoreFrom_choice:~1,-1!]
call:getNextInList restoreFrom "!restoreFrom_choice!"
CLS
GOTO:EOF

:menu_
:menu_============================================================================================
:menu_

:getTimeStamp
FOR /F "tokens=2-4 delims=/ " %%A in ("%DATE%") DO (
    SET "MM=%%A"
    SET "DD=%%B"
)
FOR /F "tokens=1-4 delims=/:." %%A in ("%TIME%") DO (
    SET "HH24=%%A"
    SET "MI=%%B"
    SET "SS=%%C"
)
SET "%~1=%MM%_%DD%_%HH24%%MI%%SS%"
GOTO :EOF

:getBkpDirList
SET "last="
SET "secondToLast="
SET "thirdToLast="
FOR /F %%A IN ('DIR /AD /B') DO (
SET "thirdToLast=!secondToLast!"
SET "secondToLast=!last!"
SET "last=%%A"
)
:END
SET "%~1=,!last!,!secondToLast!,!thirdToLast!,"
GOTO:EOF

:getNextInList 
SETLOCAL
SET lst=%~2
IF "%lst:~0,1%" NEQ "%lst:~-1%" echo.ERROR Choice list must start and end with the delimiter&GOTO:EOF
SET dlm=%lst:~-1%
SET old=!%~1!
SET fst=&FOR /F "delims=%dlm%" %%a IN ("%lst%") DO SET fst=%%a
SET lll=!lst:%dlm%%old%%dlm%=%dlm%@%dlm%!%fst%%dlm%
FOR /F "tokens=2 delims=@" %%a IN ("%lll%") DO SET lll=%%a
FOR /F "delims=%dlm%" %%a IN ("%lll%") DO SET new=%%a
( ENDLOCAL & REM RETURN VALUES
    IF "%~1" NEQ "" (SET %~1=%new%) ELSE (echo.%new%)
)
GOTO:EOF

:pauseAndClear
ECHO.Done.
PAUSE
SET "restoreFrom_choice="
call:getBkpDirList restoreFrom_choice
SET "restoreFrom="
call:getNextInList restoreFrom "!restoreFrom_choice!"
CLS
GOTO:EOF

