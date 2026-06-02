# ============================================
# Rename Ariba to Abacus - Post-Deploy Script
# ============================================
#
# NOTABLE EXCLUSIONS:
# The following directories are intentionally NOT renamed:
#
#   1. docroot/abacus/ui/branding/ariba
#   2. docroot/abacus/ui/richtext/xinha/skins/ariba
#
# REASON:
# These "ariba" directories are SKIN/NAME directories (not path markers).
# They contain CSS, images, and other assets that are referenced via
# RELATIVE paths within CSS files, e.g.:
#     background: url(cssSelectArrow.gif);
#
# The CSS file at docroot/abacus/ui/branding/ariba/widgets.css loads
# images from the SAME directory using relative paths, so renaming
# the directory would break those references.
#
# Additionally, code references exist for "branding/ariba" path:
#     AWConcreteServerApplication.java:392:
#         File resourceDir = new File(path, "resource/webserver/branding/ariba");
#
# Since HTML-generated URLs are already rewritten to use /abacus/ prefix,
# the browser will correctly load these skin assets.
#
# ============================================
param(
    [switch]$CompileOnly
)

$ErrorActionPreference = "Stop"

$AW_HOME = "C:\tmp\aribaweb"
$DEMO_DIR = Join-Path $AW_HOME "examples\Demo"
$DeployDocroot = Join-Path $DEMO_DIR "build\tomcat-bases\Demo\webapps\Demo\docroot"
$SrcAribaweb = Join-Path $AW_HOME "src\aribaweb"
$BuildLib = Join-Path $SrcAribaweb "build\lib"
$DeployLib = Join-Path $DEMO_DIR "build\tomcat-bases\Demo\webapps\Demo\WEB-INF\lib"

function Write-LogInfo {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-LogWarn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Ariba to Abacus Rename Script" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Compile aribaweb module
Write-LogInfo "Step 1: Compiling aribaweb module..."

$env:AW_HOME = $AW_HOME
$env:ANT_HOME = "C:\apache-ant-1.10.17"

Set-Location $SrcAribaweb
$compileCmd = "$env:ANT_HOME\bin\ant.bat jar"
Write-Host "Running: $compileCmd" -ForegroundColor Gray
& cmd.exe /c $compileCmd 2>&1 | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Compilation failed!" -ForegroundColor Red
    exit 1
}
Write-LogInfo "Compilation successful!"

# Step 2: Copy new jar to deployment
Write-LogInfo "Step 2: Copying new jar to deployment..."
$SrcJar = Join-Path $BuildLib "ariba.aribaweb.jar"
$DstJar = Join-Path $DeployLib "ariba.aribaweb.jar"

if (Test-Path $SrcJar) {
    Copy-Item -Path $SrcJar -Destination $DstJar -Force
    Write-LogInfo "Copied: $SrcJar -> $DstJar"
} else {
    Write-Host "[ERROR] Source jar not found: $SrcJar" -ForegroundColor Red
    exit 1
}

if ($CompileOnly) {
    Write-Host ""
    Write-LogInfo "CompileOnly mode, skipping file renaming."
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "Done! (Compile only)" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    exit 0
}

# Step 3: Rename directory ariba -> abacus
Write-LogInfo "Step 3: Renaming docroot/ariba -> docroot/abacus..."
$SrcDir = Join-Path $DeployDocroot "ariba"
$DstDir = Join-Path $DeployDocroot "abacus"

if (Test-Path $DstDir) {
    Write-LogWarn "Destination already exists: $DstDir"
    Write-LogWarn "Skipping directory rename."
} elseif (Test-Path $SrcDir) {
    Rename-Item -Path $SrcDir -NewName "abacus" -Force
    Write-LogInfo "Renamed: $SrcDir -> $DstDir"
} else {
    Write-LogWarn "Source directory not found: $SrcDir"
}

# Step 4: Rename files containing aribaweb -> abacusweb
Write-LogInfo "Step 4: Renaming files (aribaweb -> abacusweb)..."
$FilesToRename = Get-ChildItem -Path $DstDir -Recurse -Filter "*aribaweb*" -ErrorAction SilentlyContinue
$RenamedCount = 0

foreach ($file in $FilesToRename) {
    $newName = $file.Name.Replace("aribaweb", "abacusweb")
    if ($file.Name -ne $newName) {
        Rename-Item -Path $file.FullName -NewName $newName -Force
        Write-Host "  Renamed: $($file.Name) -> $newName" -ForegroundColor Gray
        $RenamedCount++
    }
}

Write-LogInfo "Renamed $RenamedCount file(s)"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Done! Ariba -> Abacus rename completed." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
