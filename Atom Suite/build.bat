@echo off
 set bigspr=0
 if "%2"=="b" set bigspr=24
 if "%3"=="b" set bigspr=24
 if "%4"=="b" set bigspr=24
 if "%5"=="b" set bigspr=24
 if "%6"=="b" set bigspr=24

rem Compile AGD file
 cls
 copy %1.agd agd >nul
 if errorlevel 1 goto error
 cd AGD

 if %bigspr%==24 goto agd24
 AGD %1
 goto cont

:agd24
 AGD24 %1
:cont
 copy %1.inc ..\cc65\ >nul
 copy game.cfg ..\cc65\ >nul
 del %1.*
 del game.cfg

rem Assemble file
 cd ..\cc65
 call make %1 %2 %3 %4 %5 %6 %7 %8 %9
 copy %1.atm ..\atomulator\mmc\menu >nul
 del %1.*

rem Start emulator
 echo Starting emulator with %1.atm
 cd ..\atomulator
 atomulator -autoboot
 echo Quiting emulator
 del mmc\menu
 cd ..
 goto end

:error
 echo %1.agd not found .....

:end
