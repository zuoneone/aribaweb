@rem ##########################################################################
@rem
@rem  Bootstrap script for running AribaWeb Gradle commands
@rem
@rem ##########################################################################
@if "%DEBUG%" == "" @echo off
if "%OS%"=="Windows_NT" setlocal EnableDelayedExpansion

:check_JAVA_HOME
if not defined JAVA_HOME goto err_JAVA_HOME
set "CLEAN_JAVA_HOME=%JAVA_HOME%"
:strip_java
if "!CLEAN_JAVA_HOME:~-1!"==" " (
    set "CLEAN_JAVA_HOME=!CLEAN_JAVA_HOME:~0,-1!"
    goto strip_java
)
rem Remove quotes if any
set "CLEAN_JAVA_HOME=!CLEAN_JAVA_HOME:"=!"
if not exist "!CLEAN_JAVA_HOME!\bin\java.exe" (
    echo JAVA_HOME is not set up correctly: %JAVA_HOME%
    goto end
)
echo Setting JAVA_HOME to: !CLEAN_JAVA_HOME!

:check_GRADLE_HOME
if not defined GRADLE_HOME goto err_GRADLE_HOME
set "CLEAN_GRADLE_HOME=%GRADLE_HOME%"
:strip_gradle
if "!CLEAN_GRADLE_HOME:~-1!"==" " (
    set "CLEAN_GRADLE_HOME=!CLEAN_GRADLE_HOME:~0,-1!"
    goto strip_gradle
)
rem Remove quotes if any
set "CLEAN_GRADLE_HOME=!CLEAN_GRADLE_HOME:"=!"
if not exist "!CLEAN_GRADLE_HOME!\bin\gradle.bat" (
    echo GRADLE_HOME is not set up correctly: %GRADLE_HOME%
    goto end
)
echo Setting GRADLE_HOME to: !CLEAN_GRADLE_HOME!

set "JAVA_HOME=!CLEAN_JAVA_HOME!"
set "PATH=!CLEAN_JAVA_HOME!\bin;!CLEAN_GRADLE_HOME!\bin;!PATH!"

rem Execute Gradle
echo Running Gradle...
call "!CLEAN_GRADLE_HOME!\bin\gradle.bat" %*
goto end

:err_JAVA_HOME
echo Please set up JAVA_HOME environment variable first.
goto end

:err_GRADLE_HOME
echo Please set up GRADLE_HOME environment variable first.
goto end

:end
if "%OS%"=="Windows_NT" endlocal
