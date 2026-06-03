@echo off
setlocal enabledelayedexpansion

rem ============================================
rem AribaWeb Production Build & Deploy Script
rem ============================================

set "JAVA_HOME=C:\Program Files\Java\jdk1.8.0_392"
set "ANT_HOME=C:\apache-ant-1.10.17"
set "CATALINA_HOME=C:\apache-tomcat-9.0.118"

set "AW_HOME=%~dp0.."
set "RENAME_SCRIPT=%~dp0\rename-assets.ps1"

echo ============================================
echo  AribaWeb Production Build & Deploy
echo ============================================

echo.
echo [1/4] Building project (production mode)
cd "%AW_HOME%"

call "%AW_HOME%\bin\aw.bat" ant -f build.xml jars -Ddebug.off=true
if %ERRORLEVEL% neq 0 (
    echo Build failed!
    pause
    exit /b 1
)

echo.
echo [2/4] Deploying demo application
call "%AW_HOME%\bin\aw.bat" ant -f build.xml webapps -Ddebug.off=true
if %ERRORLEVEL% neq 0 (
    echo Deploy failed!
    pause
    exit /b 1
)

echo.
echo [3/4] Renaming resource files
powershell.exe -ExecutionPolicy Bypass -File "%RENAME_SCRIPT%"
if %ERRORLEVEL% neq 0 (
    echo Resource rename failed!
    pause
    exit /b 1
)

echo.
echo [4/4] Starting Tomcat (without rebuilding)
rem Use "tomcat" target instead of "tomcat-build-browse" to avoid rebuilding webapps/Demo,
rem which would overwrite the renamed resources from step 3.
call "%AW_HOME%\bin\aw.bat" ant -f build.xml tomcat -Ddebug.off=true

if %ERRORLEVEL% neq 0 (
    echo Tomcat start failed!
    pause
    exit /b 1
)

echo.
echo ============================================
echo  Deployment completed!
echo  Access URL: http://localhost:9080/Demo/AribaWeb
echo ============================================
pause