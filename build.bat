@echo off

rem Compile AGD file
 copy %1.agd agd
 cd AGD
 AGD %1
 copy %1.inc ..\cc65\
 del %1.*

rem Assemble game
 cd ..\cc65
 call make %1
 copy %1.atm ..\atomulator\mmc\menu
 del %1.*

rem Start emulator
 cd ..\atomulator
 atomulator -autoboot
 del mmc\menu
 cd ..
