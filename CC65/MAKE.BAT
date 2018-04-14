@echo off
 echo Assembling %1
 if "%2"=="" goto NoFontIncluded

:FontIncluded
 echo .include "%1.inc" >game.inc
 echo .include "%2%.inc" >>game.inc
 goto CompileGame

:NoFontIncluded
 echo .include "%1.inc" >game.inc

:CompileGame
 ca65 -l -o %1.o game.asm 
 if not "%errorlevel%" == "0" goto failed
 echo Linking %1
 ld65 %1.o -C atom.cfg -o %1.atm 
 if not "%errorlevel%" == "0" goto failed
 copy %1.atm "C:\Emulator\Atomulator Phill\mmc"
 echo Finished, created %1.atm
 goto end

:failed
echo.
echo Error %errorlevel%
echo.

:end
del *.o


