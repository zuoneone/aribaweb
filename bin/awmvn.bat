@echo off
rem Retrieve JAVA_HOME and MAVEN_HOME from the environment.
rem If not defined, fallback to the detected installations on this system.

if "%JAVA_HOME%"=="" (
    set "JAVA_HOME=C:\jdk17012"
)
if "%MAVEN_HOME%"=="" (
    set "MAVEN_HOME=C:\apache-maven-3.9.16"
)

echo [INFO] Using JAVA_HOME: %JAVA_HOME%
echo [INFO] Using MAVEN_HOME: %MAVEN_HOME%

rem Set local path environment to ensure Maven 3.9.16 and JDK 17.0.12 are used first.
set "PATH=%MAVEN_HOME%\bin;%JAVA_HOME%\bin;%PATH%"

rem Set MAVEN_OPTS to allow reflection access under JDK 17
set "MAVEN_OPTS=--add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.lang.reflect=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.base/java.io=ALL-UNNAMED --add-opens=java.base/java.nio=ALL-UNNAMED --add-opens=java.base/java.math=ALL-UNNAMED --add-opens=java.base/java.net=ALL-UNNAMED --add-opens=java.base/java.text=ALL-UNNAMED --add-opens=java.rmi/sun.rmi.transport=ALL-UNNAMED --add-opens=java.xml/com.sun.org.apache.xerces.internal.jaxp=ALL-UNNAMED --add-opens=java.xml/com.sun.org.apache.xerces.internal.impl=ALL-UNNAMED --add-opens=java.xml/com.sun.org.apache.xerces.internal.dom=ALL-UNNAMED --add-opens=java.xml/com.sun.org.apache.xerces.internal.parsers=ALL-UNNAMED --add-opens=java.xml/com.sun.org.apache.xerces.internal.util=ALL-UNNAMED --add-opens=java.xml/com.sun.org.apache.xpath.internal=ALL-UNNAMED --add-opens=java.xml/com.sun.org.apache.xpath.internal.objects=ALL-UNNAMED --add-opens=java.xml/com.sun.org.apache.xalan.internal.xsltc.trax=ALL-UNNAMED --add-opens=java.xml/com.sun.org.apache.xml.internal.serializer=ALL-UNNAMED --add-opens=java.xml/com.sun.org.apache.xml.internal.utils=ALL-UNNAMED"

rem Determine project root path
set "DIRNAME=%~dp0"
if "%DIRNAME%"=="" set "DIRNAME=.\"
set "AW_HOME=%DIRNAME%.."

set "TARGET=%~1"

if "%TARGET%"=="help" (
    goto usage
)
if "%TARGET%"=="-h" (
    goto usage
)
if "%TARGET%"=="--help" (
    goto usage
)
if "%TARGET%"=="?" (
    goto usage
)

if "%TARGET%"=="" (
    echo [INFO] Running default target: package - build jars...
    call "%MAVEN_HOME%\bin\mvn.cmd" -f "%AW_HOME%\pom.xml" package -DskipTests
    goto end
)

if "%TARGET%"=="clean" (
    echo [INFO] Executing Maven clean...
    call "%MAVEN_HOME%\bin\mvn.cmd" -f "%AW_HOME%\pom.xml" clean
    goto end
)

if "%TARGET%"=="common.clean" (
    echo [INFO] Executing Maven clean...
    call "%MAVEN_HOME%\bin\mvn.cmd" -f "%AW_HOME%\pom.xml" clean
    goto end
)

if "%TARGET%"=="compile" (
    echo [INFO] Executing Maven compile...
    call "%MAVEN_HOME%\bin\mvn.cmd" -f "%AW_HOME%\pom.xml" compile
    goto end
)

if "%TARGET%"=="copy-resources" (
    echo [INFO] Executing Maven compile to copy and prepare resources...
    call "%MAVEN_HOME%\bin\mvn.cmd" -f "%AW_HOME%\pom.xml" compile
    goto end
)

if "%TARGET%"=="docs" (
    echo [INFO] Generating Javadocs and Aggregate Docs...
    call "%MAVEN_HOME%\bin\mvn.cmd" -f "%AW_HOME%\pom.xml" javadoc:aggregate -DskipTests
    goto end
)

if "%TARGET%"=="jar" (
    echo [INFO] Executing Maven package - building jar files...
    call "%MAVEN_HOME%\bin\mvn.cmd" -f "%AW_HOME%\pom.xml" package -DskipTests
    goto end
)

if "%TARGET%"=="jars" (
    echo [INFO] Executing Maven package - building jar files...
    call "%MAVEN_HOME%\bin\mvn.cmd" -f "%AW_HOME%\pom.xml" package -DskipTests
    goto end
)

if "%TARGET%"=="javadocs" (
    echo [INFO] Generating aggregated Javadocs...
    call "%MAVEN_HOME%\bin\mvn.cmd" -f "%AW_HOME%\pom.xml" javadoc:aggregate -DskipTests
    goto end
)

if "%TARGET%"=="javadoc" (
    echo [INFO] Generating aggregated Javadocs...
    call "%MAVEN_HOME%\bin\mvn.cmd" -f "%AW_HOME%\pom.xml" javadoc:aggregate -DskipTests
    goto end
)

if "%TARGET%"=="launch" (
    echo [INFO] Rebuilding and launching Tomcat in a new window...
    call "%MAVEN_HOME%\bin\mvn.cmd" -f "%AW_HOME%\pom.xml" package -DskipTests
    start "Tomcat" cmd /c "%MAVEN_HOME%\bin\mvn.cmd" -f "%AW_HOME%\pom.xml" -N exec:exec -Ptomcat
    echo [INFO] Waiting 5 seconds for Tomcat to boot...
    ping -n 6 127.0.0.1 >nul
    echo [INFO] Opening Demo application in the browser...
    start http://localhost:9090/Demo/AribaWeb/
    goto end
)

if "%TARGET%"=="merge-js" (
    echo [INFO] Merging core and widgets JavaScript files...
    call "%MAVEN_HOME%\bin\mvn.cmd" -f "%AW_HOME%\pom.xml" compile -pl src/aribaweb,src/widgets -am
    goto end
)

if "%TARGET%"=="package-binary-min" (
    echo [INFO] Rebuilding and packaging binary distribution zip...
    call "%MAVEN_HOME%\bin\mvn.cmd" -f "%AW_HOME%\pom.xml" package -DskipTests
    powershell -Command "New-Item -ItemType Directory -Force -Path dist; Remove-Item -ErrorAction SilentlyContinue -Force dist/aribaweb-binary.zip; Compress-Archive -Path bin, conf, docs, examples, ide, lib, src, tools, index.html, LICENSE.txt, NOTICE.txt, README.txt, pom.xml -DestinationPath dist/aribaweb-binary.zip"
    echo [INFO] Binary package created at dist/aribaweb-binary.zip
    goto end
)

if "%TARGET%"=="package-src" (
    echo [INFO] Packaging source code distribution zip...
    powershell -Command "New-Item -ItemType Directory -Force -Path dist; Remove-Item -ErrorAction SilentlyContinue -Force dist/aribaweb-src.zip; Compress-Archive -Path bin, conf, examples, src, pom.xml, build.xml, LICENSE.txt, README.txt -DestinationPath dist/aribaweb-src.zip"
    echo [INFO] Source package created at dist/aribaweb-src.zip
    goto end
)

if "%TARGET%"=="ensure-tomcat-conf" (
    echo [INFO] Ensuring Tomcat base configuration is initialized...
    call "%MAVEN_HOME%\bin\mvn.cmd" -f "%AW_HOME%\pom.xml" validate -Ptomcat
    goto end
)

if "%TARGET%"=="tomcat" (
    echo [INFO] Starting Tomcat server natively...
    call "%MAVEN_HOME%\bin\mvn.cmd" -f "%AW_HOME%\pom.xml" -N exec:exec -Ptomcat
    goto end
)

if "%TARGET%"=="tomcat-browse" (
    echo [INFO] Starting Tomcat in a new window...
    start "Tomcat" cmd /c "%MAVEN_HOME%\bin\mvn.cmd" -f "%AW_HOME%\pom.xml" -N exec:exec -Ptomcat
    echo [INFO] Waiting 5 seconds for Tomcat to boot...
    ping -n 6 127.0.0.1 >nul
    echo [INFO] Opening Demo application in the browser...
    start http://localhost:9090/Demo/AribaWeb/
    goto end
)

if "%TARGET%"=="tomcat-build" (
    echo [INFO] Rebuilding and launching Tomcat in a new window...
    call "%MAVEN_HOME%\bin\mvn.cmd" -f "%AW_HOME%\pom.xml" package -DskipTests
    start "Tomcat" cmd /c "%MAVEN_HOME%\bin\mvn.cmd" -f "%AW_HOME%\pom.xml" -N exec:exec -Ptomcat
    echo [INFO] Waiting 5 seconds for Tomcat to boot...
    ping -n 6 127.0.0.1 >nul
    echo [INFO] Opening Demo application in the browser...
    start http://localhost:9090/Demo/AribaWeb/
    goto end
)

if "%TARGET%"=="tomcat-build-exec" (
    echo [INFO] Rebuilding and launching Tomcat in a new window...
    call "%MAVEN_HOME%\bin\mvn.cmd" -f "%AW_HOME%\pom.xml" package -DskipTests
    start "Tomcat" cmd /c "%MAVEN_HOME%\bin\mvn.cmd" -f "%AW_HOME%\pom.xml" -N exec:exec -Ptomcat
    echo [INFO] Waiting 5 seconds for Tomcat to boot...
    ping -n 6 127.0.0.1 >nul
    echo [INFO] Opening Demo application in the browser...
    start http://localhost:9090/Demo/AribaWeb/
    goto end
)

if "%TARGET%"=="tomcat-exec" (
    echo [INFO] Starting Tomcat server natively...
    call "%MAVEN_HOME%\bin\mvn.cmd" -f "%AW_HOME%\pom.xml" -N exec:exec -Ptomcat
    goto end
)

if "%TARGET%"=="webapps" (
    echo [INFO] Executing Maven package and copy-deploying expanded webapps...
    call "%MAVEN_HOME%\bin\mvn.cmd" -f "%AW_HOME%\pom.xml" package -DskipTests
    goto end
)

if "%TARGET%"=="wars" (
    echo [INFO] Executing Maven package - building war files...
    call "%MAVEN_HOME%\bin\mvn.cmd" -f "%AW_HOME%\pom.xml" package -DskipTests
    goto end
)

echo [INFO] Executing raw Maven command: mvn %*
call "%MAVEN_HOME%\bin\mvn.cmd" -f "%AW_HOME%\pom.xml" %*
goto end

:usage
echo Available targets in awmvn.bat:
echo   clean              - Clean all generated build output (mvn clean)
echo   common.clean       - Clean all generated build output (mvn clean)
echo   compile            - Compile all source files (mvn compile)
echo   copy-resources     - Copy and merge resources (mvn process-resources)
echo   docs               - Generate aggregated javadocs and site documents
echo   ensure-tomcat-conf - Ensure Tomcat base configuration is initialized
echo   jar / jars         - Compile and build jar files for core modules
echo   javadoc / javadocs - Generate aggregated Javadocs (mvn javadoc:aggregate)
echo   launch             - Rebuild webapps, boot Tomcat, and open browser window
echo   merge-js           - Merge and compress JavaScript files
echo   package-binary-min - Build all modules and package binary distribution zip
echo   package-src        - Package source code distribution zip
echo   tomcat             - Boot Tomcat natively (without rebuilding)
echo   tomcat-browse      - Boot Tomcat and open browser window
echo   tomcat-build       - Rebuild webapps, boot Tomcat, and open browser window
echo   tomcat-build-exec  - Rebuild webapps, boot Tomcat, and open browser window
echo   tomcat-exec        - Boot Tomcat natively (without rebuilding)
echo   webapps            - Compile, package, and deploy exploded webapps to Tomcat
echo   wars               - Compile and package webapps into WAR files
echo.
echo Or pass any raw Maven commands/options directly (e.g., awmvn.bat dependency:tree).
goto end

:end
