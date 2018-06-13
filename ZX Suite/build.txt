@echo off

rem Compile AGD file
 copy %1.agd agd
 cd AGD
 AGD %1
 copy %1.asm ..\sjasmplus\
 del %1.*

rem Assemble game
 cd ..\sjasmplus
 copy leader.txt+%1.asm+trailer.txt agdcode.asm
 sjasmplus.exe agdcode.asm --lst=list.txt
 copy test.tap ..\speccy
 del %1.asm
 del agdcode.asm
 del test.tap

rem Start emulator
 cd ..\speccy
 speccy test.tap
 del test.tap
 cd ..
