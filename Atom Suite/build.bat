@echo off

rem Compile AGD file
 copy %1.agd agd
 if errorlevel 1 goto error
 cd AGD
 AGD %1
 copy %1.inc ..\cc65\
 del %1.*

rem Assemble file
 cd ..\cc65
 call make %1 %2 %3 %4 %5
 copy %1.atm ..\atomulator\mmc\menu
rem del %1.*

rem Start emulator
 cd ..\atomulator
 atomulator -autoboot
 del mmc\menu
 cd ..
 goto end

:error
 echo %1.agd not found .....

:end
