:user_configuration

:: About AIR application packaging
:: http://livedocs.adobe.com/flex/3/html/help.html?content=CommandLineTools_5.html#1035959
:: http://livedocs.adobe.com/flex/3/html/distributing_apps_4.html#1037515

:: NOTICE: all paths are relative to project root

:: Your certificate information
set CERT_NAME="BatchFlash"
set CERT_PASS=D6XLKaHQaQNxjDfZwqJXMWq5avpapSrQH0G6tnEOecNYIaRqFcuMeRTJsiztXFGWjQpdzARWRHJ4yvk5fyt4nzdBIZk91TNvDTBGRpzZcZbAqtQBD7oCht2gfMTHBUbO
set CERT_FILE="bat\BatchFlash.p12"
set SIGNING_OPTIONS=-storetype pkcs12 -keystore %CERT_FILE% -storepass %CERT_PASS%

:: Application descriptor
set APP_XML=application.xml

:: Files to package
set APP_DIR=bin
set FILE_OR_DIR=-C %APP_DIR% .

:: Your application ID (must match <id> of Application descriptor)
set APP_ID=com.battybovine.BatchFlash

:: Output
set AIR_PATH=air
set AIR_NAME=BatchFlash


:validation
%SystemRoot%\System32\find /C "<id>%APP_ID%</id>" "%APP_XML%" > NUL
if errorlevel 1 goto badid
goto end

:badid
echo.
echo ERROR: 
echo   Application ID in 'bat\SetupApplication.bat' (APP_ID) 
echo   does NOT match Application descriptor '%APP_XML%' (id)
echo.
if %PAUSE_ERRORS%==1 pause
exit

:end