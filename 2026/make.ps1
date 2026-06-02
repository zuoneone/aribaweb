<#
.SYNOPSIS
    AribaWeb Project Build and Deploy Script (PowerShell)
.DESCRIPTION
    Features: Stop Tomcat -> Pre-compile (JavaCC) -> Build Project -> Deploy -> Start Tomcat
    Defaults to PRODUCTION MODE with RapidTurnaround disabled.
.NOTES
    Run in Administrator PowerShell
#>

# ============================================
# Configuration
# ============================================
$env:JAVA_HOME = "C:\Program Files\Java\jdk1.8.0_392"
$env:CATALINA_HOME = "C:\apache-tomcat-9.0.118"
$env:ANT_HOME = "C:\apache-ant-1.10.17"

# Update PATH to include Java, Tomcat, and Ant bin directories
$env:PATH = "$env:JAVA_HOME\bin;$env:CATALINA_HOME\bin;$env:ANT_HOME\bin;$env:PATH"

# Project directories
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$AW_HOME = (Get-Item $ScriptDir).Parent.FullName
$env:AW_HOME = $AW_HOME
$PROJECT_DIR = $AW_HOME
$DEMO_DIR = Join-Path $PROJECT_DIR "examples\Demo"

# Log file with timestamp
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$LOG_FILE = Join-Path $PROJECT_DIR "2026\deploy_$Timestamp.log"

# JavaCC Configuration (使用 lib/ext-build/javacc-7.0.12.jar)
$JAVACC_JAR = Join-Path $PROJECT_DIR "lib\ext-build\javacc-7.0.12.jar"

# ============================================
# Color Output Functions
# ============================================
function Write-LogInfo {
    param([string]$Message)
    $color = "Green"
    Write-Host "[INFO] $Message" -ForegroundColor $color
    Add-Content -Path $LOG_FILE -Value "[INFO] $Message"
}

function Write-LogWarn {
    param([string]$Message)
    $color = "Yellow"
    Write-Host "[WARN] $Message" -ForegroundColor $color
    Add-Content -Path $LOG_FILE -Value "[WARN] $Message"
}

function Write-LogError {
    param([string]$Message)
    $color = "Red"
    Write-Host "[ERROR] $Message" -ForegroundColor $color
    Add-Content -Path $LOG_FILE -Value "[ERROR] $Message"
}

function Write-LogDivider {
    $divider = "============================================"
    Write-Host $divider
    Add-Content -Path $LOG_FILE -Value $divider
}

# ============================================
# Generate ExprParser (expr module)
# ============================================
function Generate-ExprParser {
    Write-LogDivider
    Write-LogInfo "Generating ExprParser..."

    Set-Location $PROJECT_DIR

    $OUTPUT_DIR = Join-Path $PROJECT_DIR "build\derived-src\aribaweb-all\ariba\util\expr"
    if (-not (Test-Path $OUTPUT_DIR)) {
        New-Item -ItemType Directory -Path $OUTPUT_DIR -Force | Out-Null
    }

    # Step 1: Run JJTree
    Write-LogInfo "Running JJTree..."
    $jjtreeCmd = "java -cp `"$JAVACC_JAR`" jjtree `"$PROJECT_DIR\src\expr\ariba\util\expr\expr.jjt`""
    Invoke-Expression $jjtreeCmd 2>&1 | Add-Content -Path $LOG_FILE

    if ($LASTEXITCODE -ne 0) {
        Write-LogError "JJTree execution failed!"
        return $false
    }

    # Move generated files to output directory
    Write-LogInfo "Moving JJTree generated files..."
    Get-ChildItem -Path $PROJECT_DIR -Filter "AST*.java" | Move-Item -Destination $OUTPUT_DIR -Force
    @("Node.java", "SimpleNode.java", "ExprParserTreeConstants.java", "JJTExprParserState.java", "expr.jj") | ForEach-Object {
        $srcFile = Join-Path $PROJECT_DIR $_
        if (Test-Path $srcFile) {
            Move-Item -Path $srcFile -Destination $OUTPUT_DIR -Force
        }
    }

    # Step 2: Run JavaCC
    Write-LogInfo "Running JavaCC..."
    Set-Location $OUTPUT_DIR
    $javaccCmd = "java -cp `"$JAVACC_JAR`" javacc expr.jj"
    Invoke-Expression $javaccCmd 2>&1 | Add-Content -Path $LOG_FILE

    if ($LASTEXITCODE -ne 0) {
        Write-LogError "JavaCC execution failed!"
        return $false
    }

    # Delete generated AST classes (keep handwritten versions)
    Write-LogInfo "Cleaning generated AST classes..."
    Set-Location $PROJECT_DIR
    @("AST*.java", "Node.java", "SimpleNode.java") | ForEach-Object {
        Get-ChildItem -Path $OUTPUT_DIR -Filter $_ | Remove-Item -Force -ErrorAction SilentlyContinue
    }

    Set-Location $PROJECT_DIR
    Write-LogInfo "ExprParser generated successfully!"
    return $true
}

# ============================================
# Generate metaui Parser
# ============================================
function Generate-MetauiParser {
    Write-LogDivider
    Write-LogInfo "Generating metaui Parser..."

    $metauiDir = Join-Path $PROJECT_DIR "src\metaui"
    $originalDir = Get-Location

    Set-Location $metauiDir

    $antCmd = "$env:ANT_HOME\bin\ant.bat javacc"
    Invoke-Expression $antCmd 2>&1 | Add-Content -Path $LOG_FILE

    if ($LASTEXITCODE -ne 0) {
        Write-LogError "metaui Parser generation failed!"
        Set-Location $originalDir
        return $false
    }

    Set-Location $originalDir
    Write-LogInfo "metaui Parser generated successfully!"
    return $true
}

# ============================================
# Clean old generated files
# ============================================
function Clean-Generated {
    Write-LogDivider
    Write-LogInfo "Cleaning old generated files..."

    $dirsToClean = @(
        (Join-Path $PROJECT_DIR "build\derived-src\aribaweb-all"),
        (Join-Path $PROJECT_DIR "build\derived-src\metaui"),
        (Join-Path $PROJECT_DIR "src\metaui\build")
    )

    foreach ($dir in $dirsToClean) {
        if (Test-Path $dir) {
            Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Write-LogInfo "Clean completed!"
}

# ============================================
# Stop Tomcat
# ============================================
function Stop-Tomcat {
    Write-LogDivider
    Write-LogInfo "Stopping Tomcat..."

    $DEMO_CATALINA_BASE = Join-Path $DEMO_DIR "build\tomcat-bases\Demo"
    $PID_FILE = Join-Path $DEMO_CATALINA_BASE "tomcat.pid"

    if (Test-Path $PID_FILE) {
        $PID = Get-Content $PID_FILE -Raw
        $PID = $PID.Trim()

        if ($PID -match '^\d+$') {
            $process = Get-Process -Id $PID -ErrorAction SilentlyContinue
            if ($process) {
                Write-LogInfo "Tomcat is running, PID: $PID"

                # Graceful shutdown
                $shutdownBat = Join-Path $env:CATALINA_HOME "bin\shutdown.bat"
                if (Test-Path $shutdownBat) {
                    Start-Process -FilePath $shutdownBat -NoNewWindow -Wait
                }

                # Wait for stop
                $count = 0
                while ($count -lt 30) {
                    Start-Sleep -Seconds 1
                    $process = Get-Process -Id $PID -ErrorAction SilentlyContinue
                    if (-not $process) { break }
                    $count++
                }

                # Force kill if still running
                $process = Get-Process -Id $PID -ErrorAction SilentlyContinue
                if ($process) {
                    Write-LogWarn "Tomcat did not stop gracefully, killing process"
                    Stop-Process -Id $PID -Force -ErrorAction SilentlyContinue
                }

                Remove-Item -Path $PID_FILE -Force -ErrorAction SilentlyContinue
                Write-LogInfo "Tomcat stopped"
            }
            else {
                Write-LogInfo "Tomcat process not found, removing stale PID file"
                Remove-Item -Path $PID_FILE -Force -ErrorAction SilentlyContinue
            }
        }
    }
    else {
        Write-LogInfo "Tomcat is not running (no PID file)"
    }
}

# ============================================
# Compile project
# ============================================
function Compile-Project {
    Write-LogDivider
    Write-LogInfo "Building project..."

    if (-not (Test-Path $env:JAVA_HOME)) {
        Write-LogError "JAVA_HOME does not exist: $env:JAVA_HOME"
        return $false
    }

    Set-Location $PROJECT_DIR

    # Run ant clean
    Write-LogInfo "Running ant clean..."
    $antCleanCmd = "$env:ANT_HOME\bin\ant.bat clean"
    Invoke-Expression $antCleanCmd 2>&1 | Add-Content -Path $LOG_FILE

    if ($LASTEXITCODE -ne 0) {
        Write-LogError "Clean failed!"
        return $false
    }

    # Regenerate ExprParser (clean deletes derived-src)
    Write-LogInfo "Regenerating ExprParser..."
    if (-not (Generate-ExprParser)) {
        return $false
    }

    # Build JARs
    Write-LogInfo "Running ant jars..."
    $antJarsCmd = "$env:ANT_HOME\bin\ant.bat jars"
    Invoke-Expression $antJarsCmd 2>&1 | Add-Content -Path $LOG_FILE

    if ($LASTEXITCODE -ne 0) {
        Write-LogError "JAR build failed!"
        return $false
    }

    Write-LogInfo "Build completed!"
    return $true
}

# ============================================
# Deploy Demo application (build only)
# ============================================
function Deploy-Demo {
    Write-LogDivider
    Write-LogInfo "Deploying Demo application (PRODUCTION MODE)..."

    Set-Location $DEMO_DIR

    # 生产模式：传递 -Ddebug.off=true 禁用 RapidTurnaround
    $buildArgs = "`"-Ddebug.off=true`""

    # Step 1: 构建 jar 和 webapp
    Write-LogInfo "Building jar and webapp..."
    $buildJarCmd = "$env:ANT_HOME\bin\ant.bat jar webapp $buildArgs"
    Write-LogInfo "Running: $buildJarCmd"
    Invoke-Expression $buildJarCmd 2>&1 | Add-Content -Path $LOG_FILE

    if ($LASTEXITCODE -ne 0) {
        Write-LogError "Build failed!"
        return $false
    }

    Write-LogInfo "Demo application deployed successfully!"
    return $true
}

# ============================================
# Start Tomcat
# ============================================
function Start-Tomcat {
    Write-LogDivider
    Write-LogInfo "Starting Tomcat..."

    Set-Location $DEMO_DIR

    # 生产模式参数
    $buildArgs = "`"-Ddebug.off=true`""

    # 使用 Start-Process 在后台启动，不等待
    # 环境变量已在脚本开头设置，直接运行 ant
    $startTomcatCmd = "$env:ANT_HOME\bin\ant.bat tomcat $buildArgs"
    Write-LogInfo "Running: $startTomcatCmd"
    
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "set AW_HOME=$env:AW_HOME& $startTomcatCmd" -WorkingDirectory $DEMO_DIR -WindowStyle Normal

    Write-LogInfo "Tomcat is starting in background. Please wait a few seconds for it to fully start."
    Write-LogInfo "Access the application at: http://localhost:8080/Demo/AribaWeb"
    return $true
}

# ============================================
# Show help
# ============================================
function Show-Help {
    Write-Host "AribaWeb Build and Deploy Script v1.2 (PowerShell)"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  .\make.ps1           - Full build, deploy and start (Production Mode)"
    Write-Host "  .\make.ps1 clean     - Clean generated files only"
    Write-Host "  .\make.ps1 -h        - Show this help"
    Write-Host ""
    Write-Host "Production Mode:"
    Write-Host "  - RapidTurnaround disabled (IsRapidTurnaroundEnabled=false)"
    Write-Host "  - Resources served from deployment directory (webapps/Demo/docroot)"
    Write-Host "  - Requires rebuild to see code changes"
    Write-Host ""
    Write-Host "Features:"
    Write-Host "  1. Download JavaCC (if needed)"
    Write-Host "  2. Clean old generated files"
    Write-Host "  3. Stop Tomcat"
    Write-Host "  4. Generate ExprParser (JJTree+JavaCC)"
    Write-Host "  5. Generate metaui Parser (Ant javacc task)"
    Write-Host "  6. Build full project"
    Write-Host "  7. Build and start Demo application"
    Write-Host "  8. Rename ariba to abacus (post-deploy step)"
    Write-Host ""
    Write-Host "Log file: $LOG_FILE"
    Write-Host ""
}

# ============================================
# Main
# ============================================
function Main {
    # Clear log
    "" | Set-Content -Path $LOG_FILE -Force

    Write-LogDivider
    Write-LogInfo "AribaWeb Build and Deploy Script started"
    Write-LogInfo "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-LogInfo "JAVA_HOME: $env:JAVA_HOME"
    Write-LogInfo "CATALINA_HOME: $env:CATALINA_HOME"
    Write-LogInfo "AW_HOME: $AW_HOME"

    # Check arguments
    if ($args -contains "-h") {
        Show-Help
        exit 0
    }

    if ($args -contains "clean") {
        Clean-Generated
        Write-LogInfo "Only cleaned generated files, script ended"
        exit 0
    }

    Write-LogInfo "Running in PRODUCTION MODE"

    # Clean old generated files
    Clean-Generated

    # Stop Tomcat
    Stop-Tomcat

    # Compile project
    if (-not (Compile-Project)) { exit 1 }

    # Deploy Demo (build only, don't start yet)
    if (-not (Deploy-Demo)) { exit 1 }

    # Rename ariba to abacus (pre-start step)
    Write-LogInfo "Running rename script..."
    & "$ScriptDir\rename-assets.ps1"

    # Start Tomcat
    if (-not (Start-Tomcat)) { exit 1 }

    Write-LogDivider
    Write-LogInfo "Script execution completed!"
    Write-LogInfo "Log file: $LOG_FILE"
    Write-LogInfo "Access application: http://localhost:8080/Demo/AribaWeb"
}

# Run main
Main @args