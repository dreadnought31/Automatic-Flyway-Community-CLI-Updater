# Flyway Updater (Windows) - latest + GitHub primary + Redgate fallback + install + verify
# Logs to D:\flywayinstall.txt
# version 1.0
# Alan O'Brien 

$ErrorActionPreference = "Stop"
Start-Transcript -Path "D:\flywayinstall.txt" -Append

$flywayInstallPath = "D:\Flyway"
$Downloads         = "D:\temp\flywaydownloads"
$TempExtractRoot   = "D:\temp\flyway_extract"

function Ensure-Dir([string] $p) {
    if (-not (Test-Path $p)) {
        New-Item -ItemType Directory -Path $p -Force | Out-Null
    }
}

function Get-LatestFlywayVersion {
    $api = "https://api.github.com/repos/flyway/flyway/releases/latest"
    $headers = @{
        "User-Agent" = "FlywayUpdaterScript"
        "Accept"     = "application/vnd.github+json"
    }

    $rel = Invoke-RestMethod -Uri $api -Headers $headers -Method Get -ErrorAction Stop
    if (-not $rel.tag_name) {
        throw "GitHub response missing tag_name."
    }

    return ($rel.tag_name -replace "^flyway-", "")
}

function Try-Download([string] $url, [string] $outPath) {
    try {
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        } catch {}

        Write-Host "Downloading: $url" -ForegroundColor Cyan
        Invoke-WebRequest -Uri $url -OutFile $outPath -UseBasicParsing -ErrorAction Stop
        return $true
    }
    catch {
        Write-Warning ("Download failed: " + $_.Exception.Message)
        return $false
    }
}

function Fast-ExtractZip([string] $zipPath, [string] $destPath) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null

    if (Test-Path $destPath) {
        Remove-Item -Path $destPath -Recurse -Force -ErrorAction SilentlyContinue
    }

    New-Item -ItemType Directory -Path $destPath -Force | Out-Null

    Write-Host "Extracting..." -ForegroundColor Green
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $destPath)
}

Write-Host "Preparing folders..." -ForegroundColor Green
Ensure-Dir $Downloads
Ensure-Dir $TempExtractRoot
Ensure-Dir $flywayInstallPath

Write-Host "Cleaning up old Flyway installation..." -ForegroundColor Green
Get-ChildItem -Path $flywayInstallPath -Force -ErrorAction SilentlyContinue |
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Detecting latest Flyway version..." -ForegroundColor Green
$onlineVersion = Get-LatestFlywayVersion
Write-Host "Latest Flyway version detected: $onlineVersion" -ForegroundColor Green

$zipFileName = "flyway-commandline-$onlineVersion-windows-x64.zip"
$zipPath     = Join-Path $Downloads $zipFileName

# GitHub primary, Redgate fallback
$githubUrl  = "https://github.com/flyway/flyway/releases/download/flyway-$onlineVersion/$zipFileName"
$redgateUrl = "https://download.red-gate.com/maven/release/com/redgate/flyway/flyway-commandline/$onlineVersion/$zipFileName"

if (Test-Path $zipPath) {
    Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue
}

Write-Host "Downloading Flyway $onlineVersion..." -ForegroundColor Green
$downloaded = Try-Download -url $githubUrl -outPath $zipPath

if (-not $downloaded) {
    Write-Host "GitHub download failed, trying Redgate..." -ForegroundColor Yellow
    $downloaded = Try-Download -url $redgateUrl -outPath $zipPath
}

if (-not $downloaded -or -not (Test-Path $zipPath)) {
    Stop-Transcript
    throw "Could not download Flyway $onlineVersion."
}

Write-Host "Extracting to $TempExtractRoot ..." -ForegroundColor Green
Fast-ExtractZip -zipPath $zipPath -destPath $TempExtractRoot

$extractedFolder = Join-Path $TempExtractRoot "flyway-$onlineVersion"

if (-not (Test-Path $extractedFolder)) {
    $candidate = Get-ChildItem -Path $TempExtractRoot -Directory -Filter "flyway-*" |
        Select-Object -First 1

    if ($null -eq $candidate) {
        Stop-Transcript
        throw "Could not find extracted Flyway folder under $TempExtractRoot"
    }

    $extractedFolder = $candidate.FullName
}

Write-Host "Installing to $flywayInstallPath..." -ForegroundColor Green
Copy-Item -Path "$extractedFolder\*" -Destination $flywayInstallPath -Recurse -Force -ErrorAction Stop

$installedCmd = Join-Path $flywayInstallPath "flyway.cmd"

if (-not (Test-Path $installedCmd)) {
    Write-Host "Install folder contents:" -ForegroundColor Yellow
    Get-ChildItem -Path $flywayInstallPath -Recurse | Select-Object FullName
    Stop-Transcript
    throw "Install failed: flyway.cmd not found in $flywayInstallPath"
}

Write-Host "Cleanup temporary files..." -ForegroundColor Green
Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue
Remove-Item -Path $TempExtractRoot -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Confirm Flyway is updated:" -ForegroundColor Green
& $installedCmd --version

Stop-Transcript