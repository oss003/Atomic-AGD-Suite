@echo off
 set bigspr=0
 if "%2"=="b" set bigspr=24
 echo.

rem Covert ZX snapshot to AGD file
 copy ..\snapshots\%1.sna convert
 if errorlevel 1 goto error
 cd convert

 if %bigspr%==24 goto conv24
 echo Convert 16x16
 convert %1
 goto cont

:conv24
 echo Convert 16x24
 convert24 %1
:cont
 copy %1.agd ..\
 del %1.sna
 cd ..
 goto end

:error
 echo %1.agd not found .....

:end
