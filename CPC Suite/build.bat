@echo off

rem Compile AGD file
 copy %1.agd agd
 cd AGD
 AGD %1
 copy %1.asm ..\pasmo
 del %1.*

rem Assemble game
 cd ..\pasmo
 pasmo %1.asm AGDgame.bin
 if errorlevel 1 goto error
 copy AGDgame.bin ..\CPCDiskXP
 del %1.asm
 del AGDgame.bin

rem Create CPC diskimage
 cd ..\CPCDiskXP
 CPCDiskXP -File AGDgame.bin -AddAmsdosHeader 7D0 -AddToNewDsk AGDgames.dsk 
 copy AGDgames.dsk ..\WinAPE
 del AGDgame.bin
 del AGDgames.dsk

rem Start emulator
 cd ..\winape
 winape "%cd%\AGDgames.dsk" /A:AGDgame.bin
 cd ..
 goto end

:error
 echo %1.agd not found .....

:end
