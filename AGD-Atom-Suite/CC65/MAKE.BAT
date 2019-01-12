@echo off

rem Set flags

 set if=0
 if "%2"=="i" set if=1
 if "%3"=="i" set if=1
 if "%4"=="i" set if=1
 if "%5"=="i" set if=1
 if "%6"=="i" set if=1

 set af=0
 if "%2"=="a" set af=1
 if "%3"=="a" set af=1
 if "%4"=="a" set af=1
 if "%5"=="a" set af=1
 if "%6"=="a" set af=1

 set hf=0
 if "%2"=="h" set hf=1
 if "%3"=="h" set hf=1
 if "%4"=="h" set hf=1
 if "%5"=="h" set hf=1
 if "%6"=="h" set hf=1

 set gf=0
 if "%2"=="g" set gf=1
 if "%3"=="g" set gf=1
 if "%4"=="g" set gf=1
 if "%5"=="g" set gf=1
 if "%6"=="g" set gf=1

 set bf=0
 if "%2"=="b" set bf=1
 if "%3"=="b" set bf=1
 if "%4"=="b" set bf=1
 if "%5"=="b" set bf=1
 if "%6"=="b" set bf=1

rem Build asm file
 echo Building: %1
 echo .include "%1.inc" >game.inc

rem Conditional assemble game
 echo.
 echo Assemble: game.asm
 ca65 -l game.lst -o %1.o game.asm -D iflag=%if% -D aflag=%af% -D hflag=%hf% -D gflag=%gf% -D bflag=%bf%
 if not "%errorlevel%" == "0" goto failed

rem Linking
 echo.
 echo Linking: %1
 ld65  %1.o -C atom.cfg -o %1.atm 
 if not "%errorlevel%" == "0" goto failed

rem copy %1.atm "C:\Emulator\Atomulator Phill\mmc"
 echo.
 echo Copying: %1
 echo Finished, created %1.atm
 echo.
 goto end

:failed
echo.
echo Error %errorlevel%
 echo.
 echo Usage: build [agd file] [condition0] [condition1] [condition2]
 echo.
 echo Conditional assembly:
 echo a = Adventuremode
 echo b = Big Sprites (16x24)
 echo g = Graphic colour mode
 echo h = Hidden sprite mode
 echo i = Invertmode
 echo.


:end
del *.o


