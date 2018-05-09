@echo off

rem Set flags
 set mf=0
 if "%2"=="m" set mf=1
 if "%3"=="m" set mf=1
 if "%4"=="m" set mf=1

 set pf=0
 if "%2"=="p" set pf=1
 if "%3"=="p" set pf=1
 if "%4"=="p" set pf=1

 set sf=0
 if "%2"=="s" set sf=1
 if "%3"=="s" set sf=1
 if "%4"=="s" set sf=1

rem Build asm file
 echo.
 echo Build %1.inc
 echo .include "%1.inc" >game.inc

rem Conditional assemble game
 echo.
 echo Assemble: %1
 if %mf%==1 echo - Menu/inventory code loaded ...
 if %pf%==1 echo - Particle code loaded ...
 if %sf%==1 echo - Scrollytext code loaded ...
 ca65 -l -o %1.o game.asm -D mflag=%mf% -D pflag=%pf% -D sflag=%sf% 
 if not "%errorlevel%" == "0" goto failed

rem Linking
 echo.
 echo Linking: %1
 ld65 %1.o -C atom.cfg -o %1.atm 
 if not "%errorlevel%" == "0" goto failed

rem copy %1.atm "C:\Emulator\Atomulator Phill\mmc"
 echo.
 echo Copying: %1
 echo Finished, created %1.atm
 goto end

:failed
echo.
echo Error %errorlevel%
 echo.
 echo Usage: build [agd file] m p s
 echo.
 echo Conditional assembly:
 echo m = Add menu/inventory code
 echo p = Add particle code
 echo s = Add scrollytext code
 echo.


:end
del *.o


