<#
.SYNOPSIS
    AribaWeb Cache and Build Output Cleanup Script (PowerShell)
.DESCRIPTION
    Cleans up build artifacts, cached files, and deployment outputs to free up space.
    Stops Tomcat before cleanup to avoid file locking issues.
.NOTES
    Run in PowerShell with appropriate permissions
#>

param(
    [switch]$SkipTomcatStop
)

$ErrorActionPreference = "Continue"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_DIR = (Get-Item $ScriptDir).Parent.FullName
$DEMO_DIR = Join-Path $PROJECT_DIR "examples\Demo"

function Write-CleanInfo {
    param([string]$Message)
    Write-Host "[CLEAN] $Message" -ForegroundColor Cyan
}

function Stop-TomcatIfRunning {
    Write-CleanInfo "Checking for running Tomcat processes..."

    $tomcatProcesses = Get-Process java -ErrorAction SilentlyContinue | Where-Object {
        $_.Path -like "*tomcat*" -or $_.CommandLine -like "*catalina*"
    }

    if ($tomcatProcesses) {
        Write-CleanInfo "Stopping Tomcat processes..."
        foreach ($proc in $tomcatProcesses) {
            Write-CleanInfo "  Stopping PID: $($proc.Id)"
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        }
        Start-Sleep -Seconds 2
    }

    $catalinaBase = Join-Path $DEMO_DIR "build\tomcat-bases\Demo"
    $pidFile = Join-Path $catalinaBase "tomcat.pid"
    if (Test-Path $pidFile) {
        Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Magenta
Write-Host "  AribaWeb Cache Cleanup Script v1.1" -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Magenta
Write-Host ""
Write-CleanInfo "Project directory: $PROJECT_DIR"

if (-not $SkipTomcatStop) {
    Stop-TomcatIfRunning
}

Write-Host ""
Write-CleanInfo "Starting cleanup..."

$cleanPaths = @(
    @{ Path = Join-Path $PROJECT_DIR "build"; Desc = "Root build directory" },
    @{ Path = Join-Path $DEMO_DIR "build"; Desc = "Demo build directory" },
    @{ Path = Join-Path $PROJECT_DIR "src\metaui\build"; Desc = "Metaui build directory" }
)

$totalSize = 0
$removedCount = 0

foreach ($item in $cleanPaths) {
    if (Test-Path $item.Path) {
        $size = (Get-ChildItem -Path $item.Path -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
        if ($size -eq $null) { $size = 0 }
        $sizeMB = [math]::Round($size / 1MB, 2)
        $totalSize += $sizeMB
        Write-CleanInfo "Removing $($item.Desc) ($sizeMB MB)..."
        Write-CleanInfo "  $($item.Path)"
        Remove-Item -Path $item.Path -Recurse -Force -ErrorAction SilentlyContinue
        if (-not (Test-Path $item.Path)) {
            $removedCount++
        }
    } else {
        Write-CleanInfo "  $($item.Desc) not found, skipping."
    }
}

Write-CleanInfo "Removing old deployment logs..."
$logFiles = Get-ChildItem -Path (Join-Path $PROJECT_DIR "2026\deploy_*.log") -ErrorAction SilentlyContinue
if ($logFiles) {
    foreach ($file in $logFiles) {
        Write-CleanInfo "  $($file.Name)"
        Remove-Item $file.FullName -Force -ErrorAction SilentlyContinue
    }
}

# Write-CleanInfo "Removing JavaCC jar..."
# $javaccFiles = Get-ChildItem -Path (Join-Path $PROJECT_DIR "javacc-*.jar") -ErrorAction SilentlyContinue
# if ($javaccFiles) {
#     foreach ($file in $javaccFiles) {
#         Write-CleanInfo "  $($file.Name)"
#         Remove-Item $file.FullName -Force -ErrorAction SilentlyContinue
#     }
# }

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-CleanInfo "Cleanup completed!"
Write-CleanInfo "Space freed: $totalSize MB"
Write-CleanInfo "Directories removed: $removedCount"
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-CleanInfo "To rebuild the project, run:"
Write-Host "  .\make.ps1           (Development Mode)" -ForegroundColor Yellow
Write-Host "  .\make.ps1 -prod    (Production Mode)" -ForegroundColor Yellow
Write-Host ""
