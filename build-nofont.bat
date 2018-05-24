@echo off

rem Compile AGD file
 copy %1.agd agd
 cd AGD
 AGD-nofont %1
 copy %1.inc ..\cc65\
 del %1.*

rem Assemble game
 cd ..\cc65
 call make %1
 del %1.*

rem Start emulator
rem cd ..\atomulator
rem atomulator speccy test.tap
rem del test.tap
 cd ..
