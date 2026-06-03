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

if "%TARGET%"=="compile" (
    echo [INFO] Executing Maven compile...
    call "%MAVEN_HOME%\bin\mvn.cmd" -f "%AW_HOME%\pom.xml" compile
    goto end
)

if "%TARGET%"=="jars" (
    echo [INFO] Executing Maven package - building jar files...
    call "%MAVEN_HOME%\bin\mvn.cmd" -f "%AW_HOME%\pom.xml" package -DskipTests
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

if "%TARGET%"=="tomcat" (
    echo [INFO] Starting Tomcat server natively...
    call "%MAVEN_HOME%\bin\mvn.cmd" -f "%AW_HOME%\pom.xml" -N exec:exec -Ptomcat
    goto end
)

if "%TARGET%"=="launch" (
    echo [INFO] Rebuilding and launching Tomcat server...
    call "%MAVEN_HOME%\bin\mvn.cmd" -f "%AW_HOME%\pom.xml" package -DskipTests
    call "%MAVEN_HOME%\bin\mvn.cmd" -f "%AW_HOME%\pom.xml" -N exec:exec -Ptomcat
    goto end
)

if "%TARGET%"=="tomcat-build" (
    echo [INFO] Rebuilding and launching Tomcat server...
    call "%MAVEN_HOME%\bin\mvn.cmd" -f "%AW_HOME%\pom.xml" package -DskipTests
    call "%MAVEN_HOME%\bin\mvn.cmd" -f "%AW_HOME%\pom.xml" -N exec:exec -Ptomcat
    goto end
)

echo [INFO] Executing raw Maven command: mvn %*
call "%MAVEN_HOME%\bin\mvn.cmd" -f "%AW_HOME%\pom.xml" %*

:end
