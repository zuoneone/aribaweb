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

rem Set MAVEN_OPTS to allow reflection access under JDK 17 (needed by the embedded Groovy compiler inside Ant tasks)
set "MAVEN_OPTS=--add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.lang.reflect=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.base/java.io=ALL-UNNAMED --add-opens=java.base/java.nio=ALL-UNNAMED --add-opens=java.base/java.math=ALL-UNNAMED --add-opens=java.base/java.net=ALL-UNNAMED --add-opens=java.base/java.text=ALL-UNNAMED --add-opens=java.rmi/sun.rmi.transport=ALL-UNNAMED --add-opens=java.xml/com.sun.org.apache.xerces.internal.jaxp=ALL-UNNAMED --add-opens=java.xml/com.sun.org.apache.xerces.internal.impl=ALL-UNNAMED --add-opens=java.xml/com.sun.org.apache.xerces.internal.dom=ALL-UNNAMED --add-opens=java.xml/com.sun.org.apache.xerces.internal.parsers=ALL-UNNAMED --add-opens=java.xml/com.sun.org.apache.xerces.internal.util=ALL-UNNAMED --add-opens=java.xml/com.sun.org.apache.xpath.internal=ALL-UNNAMED --add-opens=java.xml/com.sun.org.apache.xpath.internal.objects=ALL-UNNAMED --add-opens=java.xml/com.sun.org.apache.xalan.internal.xsltc.trax=ALL-UNNAMED --add-opens=java.xml/com.sun.org.apache.xml.internal.serializer=ALL-UNNAMED --add-opens=java.xml/com.sun.org.apache.xml.internal.utils=ALL-UNNAMED"

rem Also pass these as ANT_OPTS since the antrun plugin might spawn an Ant task that forks or respects ANT_OPTS.
set "ANT_OPTS=--add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.lang.reflect=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.base/java.io=ALL-UNNAMED --add-opens=java.base/java.nio=ALL-UNNAMED --add-opens=java.base/java.math=ALL-UNNAMED --add-opens=java.base/java.net=ALL-UNNAMED --add-opens=java.base/java.text=ALL-UNNAMED --add-opens=java.rmi/sun.rmi.transport=ALL-UNNAMED --add-opens=java.xml/com.sun.org.apache.xerces.internal.jaxp=ALL-UNNAMED --add-opens=java.xml/com.sun.org.apache.xerces.internal.impl=ALL-UNNAMED --add-opens=java.xml/com.sun.org.apache.xerces.internal.dom=ALL-UNNAMED --add-opens=java.xml/com.sun.org.apache.xerces.internal.parsers=ALL-UNNAMED --add-opens=java.xml/com.sun.org.apache.xerces.internal.util=ALL-UNNAMED --add-opens=java.xml/com.sun.org.apache.xpath.internal=ALL-UNNAMED --add-opens=java.xml/com.sun.org.apache.xpath.internal.objects=ALL-UNNAMED --add-opens=java.xml/com.sun.org.apache.xalan.internal.xsltc.trax=ALL-UNNAMED --add-opens=java.xml/com.sun.org.apache.xml.internal.serializer=ALL-UNNAMED --add-opens=java.xml/com.sun.org.apache.xml.internal.utils=ALL-UNNAMED"

rem Determine project root path
set "DIRNAME=%~dp0"
if "%DIRNAME%"=="" set "DIRNAME=.\"
set "AW_HOME=%DIRNAME%.."

rem Execute maven with the passed target parameter.
if "%~1"=="" (
    echo [INFO] Running default target: package - build jars...
    call "%MAVEN_HOME%\bin\mvn.cmd" -f "%AW_HOME%\pom.xml" package
    goto end
)

rem Check if the first argument is a profile/target.
set "IS_PROFILE=false"
set "TARGET=%~1"

if "%TARGET%"=="jars" set "IS_PROFILE=true"
if "%TARGET%"=="webapps" set "IS_PROFILE=true"
if "%TARGET%"=="wars" set "IS_PROFILE=true"
if "%TARGET%"=="clean" set "IS_PROFILE=true"
if "%TARGET%"=="tomcat-build" set "IS_PROFILE=true"
if "%TARGET%"=="tomcat-build-browse" set "IS_PROFILE=true"
if "%TARGET%"=="launch" set "IS_PROFILE=true"
if "%TARGET%"=="tomcat-exec" set "IS_PROFILE=true"
if "%TARGET%"=="tomcat-build-exec" set "IS_PROFILE=true"
if "%TARGET%"=="tomcat" set "IS_PROFILE=true"
if "%TARGET%"=="tomcat-browse" set "IS_PROFILE=true"
if "%TARGET%"=="groovysh" set "IS_PROFILE=true"
if "%TARGET%"=="site" set "IS_PROFILE=true"
if "%TARGET%"=="run-site" set "IS_PROFILE=true"
if "%TARGET%"=="javadocs" set "IS_PROFILE=true"
if "%TARGET%"=="javadocs-internal" set "IS_PROFILE=true"
if "%TARGET%"=="docs" set "IS_PROFILE=true"
if "%TARGET%"=="index-doc" set "IS_PROFILE=true"
if "%TARGET%"=="package" set "IS_PROFILE=true"
if "%TARGET%"=="package-binary" set "IS_PROFILE=true"
if "%TARGET%"=="package-src" set "IS_PROFILE=true"
if "%TARGET%"=="dist-all" set "IS_PROFILE=true"
if "%TARGET%"=="ftp-dist" set "IS_PROFILE=true"
if "%TARGET%"=="compile" set "IS_PROFILE=true"
if "%TARGET%"=="merge-js" set "IS_PROFILE=true"

if not "%IS_PROFILE%"=="true" (
    echo [INFO] Executing raw Maven command: mvn %*
    call "%MAVEN_HOME%\bin\mvn.cmd" -f "%AW_HOME%\pom.xml" %*
    goto end
)

if "%TARGET%"=="clean" (
    echo [INFO] Executing Maven clean...
    call "%MAVEN_HOME%\bin\mvn.cmd" -f "%AW_HOME%\pom.xml" clean
    goto end
)

set "PHASE=integration-test"

rem Packaging targets -> package phase
if "%TARGET%"=="jars" set "PHASE=package"
if "%TARGET%"=="webapps" set "PHASE=package"
if "%TARGET%"=="wars" set "PHASE=package"
if "%TARGET%"=="package" set "PHASE=package"
if "%TARGET%"=="package-binary" set "PHASE=package"
if "%TARGET%"=="package-src" set "PHASE=package"
if "%TARGET%"=="dist-all" set "PHASE=package"

    rem Tomcat/Launch/Groovy targets -> antrun:run goal (instant start)
    if "%TARGET%"=="tomcat-build" set "PHASE=antrun:run"
    if "%TARGET%"=="tomcat-build-browse" set "PHASE=antrun:run"
    if "%TARGET%"=="launch" set "PHASE=antrun:run"
    if "%TARGET%"=="tomcat-exec" set "PHASE=antrun:run"
    if "%TARGET%"=="tomcat-build-exec" set "PHASE=antrun:run"
    if "%TARGET%"=="tomcat" set "PHASE=antrun:run"
    if "%TARGET%"=="tomcat-browse" set "PHASE=antrun:run"
    if "%TARGET%"=="groovysh" set "PHASE=antrun:run"

rem Site/Documentation targets -> site phase
if "%TARGET%"=="site" set "PHASE=site"
if "%TARGET%"=="run-site" set "PHASE=site"
if "%TARGET%"=="javadocs" set "PHASE=site"
if "%TARGET%"=="javadocs-internal" set "PHASE=site"
if "%TARGET%"=="docs" set "PHASE=site"
if "%TARGET%"=="index-doc" set "PHASE=site"

rem Deploy targets -> deploy phase
if "%TARGET%"=="ftp-dist" set "PHASE=deploy"

rem Compile targets -> compile phase
if "%TARGET%"=="compile" set "PHASE=compile"

rem Resource targets -> process-resources phase
if "%TARGET%"=="merge-js" set "PHASE=process-resources"

echo [INFO] Executing Maven phase: %PHASE% with profile: %TARGET%
call "%MAVEN_HOME%\bin\mvn.cmd" -f "%AW_HOME%\pom.xml" %PHASE% -P%TARGET%

:end
