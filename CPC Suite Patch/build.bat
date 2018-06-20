@echo off

rem Compile AGD file
 copy %1.agd agd
 cd AGD
 AGD %1
 copy %1.asm ..\pasmo
 del %1.*

rem Assemble game
 cd ..\pasmo
 pasmo %1.asm %1.bin %1.sym
 if errorlevel 1 goto error
 copy %1.bin ..\CPCDiskXP
 del %1.asm
 del %1.bin

rem Create CPC diskimage
 cd ..\CPCDiskXP
 CPCDiskXP -File %1.bin -AddAmsdosHeader 64 -AddToNewDsk AGDgames.dsk 
 CPCDiskXP -File shining.BIN -AddToExistingDsk AGDgames.dsk 
 CPCDiskXP -File disc.BIN -AddToExistingDsk AGDgames.dsk 
 copy AGDgames.dsk ..\WinAPE
 del %1.bin
 del AGDgames.dsk

rem Start emulator
 cd ..\winape
 winape "%cd%\AGDgames.dsk" /A:disc.bin
 cd ..
 goto end

:error
 echo %1.agd not found .....

:end
