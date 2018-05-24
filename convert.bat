@echo off

rem Covert ZX snapshot to AGD file
 copy ..\snapshots\%1.sna convert
 if errorlevel 1 goto error
 cd convert
 convert %1
 copy %1.agd ..\
 del %1.sna
 cd ..
 goto end

:error
 echo %1.agd not found .....

:end
