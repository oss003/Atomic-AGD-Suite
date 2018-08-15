@echo off

rem Set flags
 set mf=0
 if "%2"=="m" set mf=1
 if "%3"=="m" set mf=1
 if "%4"=="m" set mf=1
 if "%5"=="m" set mf=1
 if "%6"=="m" set mf=1
 if "%7"=="m" set mf=1
 if "%8"=="m" set mf=1

 set pf=0
 if "%2"=="p" set pf=1
 if "%3"=="p" set pf=1
 if "%4"=="p" set pf=1
 if "%5"=="p" set pf=1
 if "%6"=="p" set pf=1
 if "%7"=="p" set pf=1
 if "%8"=="p" set pf=1

 set sf=0
 if "%2"=="s" set sf=1
 if "%3"=="s" set sf=1
 if "%4"=="s" set sf=1
 if "%5"=="s" set sf=1
 if "%6"=="s" set sf=1
 if "%7"=="s" set sf=1
 if "%8"=="s" set sf=1

 set if=0
 if "%2"=="i" set if=1
 if "%3"=="i" set if=1
 if "%4"=="i" set if=1
 if "%5"=="i" set if=1
 if "%6"=="i" set if=1
 if "%7"=="i" set if=1
 if "%8"=="i" set if=1

 set df=0
 if "%2"=="d" set df=1
 if "%3"=="d" set df=1
 if "%4"=="d" set df=1
 if "%5"=="d" set df=1
 if "%6"=="d" set df=1
 if "%7"=="d" set df=1
 if "%8"=="d" set df=1

 set af=0
 if "%2"=="a" set af=1
 if "%3"=="a" set af=1
 if "%4"=="a" set af=1
 if "%5"=="a" set af=1
 if "%6"=="a" set af=1
 if "%7"=="a" set af=1
 if "%8"=="a" set af=1

 set hf=0
 if "%2"=="h" set hf=1
 if "%3"=="h" set hf=1
 if "%4"=="h" set hf=1
 if "%5"=="h" set hf=1
 if "%6"=="h" set hf=1
 if "%7"=="h" set hf=1
 if "%8"=="h" set hf=1

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
 if %if%==1 echo - Invertmode activated ...
 if %df%==1 echo - Diggingmode activated ...
 if %af%==1 echo - Adventuremode activated ...
 if %hf%==1 echo - Hidden sprite mode activated ...

 ca65 -l -o %1.o game.asm -D mflag=%mf% -D pflag=%pf% -D sflag=%sf% -D iflag=%if% -D dflag=%df% -D aflag=%af% -D hflag=%hf%
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
 echo i = Invertmode
 echo d = Diggingmode
 echo a = Adventuremode
 echo h = Hidden sprite mode
 echo.


:end
del *.o


