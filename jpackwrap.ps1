<#
.SYNOPSIS
    Builds and packages a Maven-based Java app into a native installer using jpackage.

.DESCRIPTION
    This script:
    - Parses pom.xml for project info
    - Checks for Maven and jpackage
    - Builds the project using Maven
    - Packages it using jpackage with the appropriate settings for your OS

.PARAMETER MainClass
    Fully qualified Java main class (e.g., com.example.MainApp)

.PARAMETER LicenseFile
    Path to the license file. Default: LICENSE

.PARAMETER IconPrefix
    Base name (no extension) for icon in src/main/resources/icons/. Default: appicon

.PARAMETER OutputDir
    Directory to place the installer. Default: current directory

.PARAMETER VendorName
    Registered vendor/author name in the output package

.PARAMETER Description
    A brief description of the program

.EXAMPLE
    .\jpackwrap.ps1 -MainClass "com.example.MainApp"

.EXAMPLE
    .\jpackwrap.ps1 -MainClass "com.example.MainApp" -OutputDir "dist"

#>

param (
    [string]$MainClass,
    [string]$VendorName = "Unknown",
    [string]$LicenseFile = "LICENSE",
    [string]$IconPrefix = "appicon",
    [string]$OutputDir = ".",
    [string]$Description = "A Java application."
)

$ErrorActionPreference = "Stop"

# Reads pom.xml and extracts artifactId and version
function Get-ProjectMetadata {
    Write-Host "`nParsing pom.xml..." -ForegroundColor Green
    if (-not (Test-Path "pom.xml")) {
        throw "pom.xml not found in current directory. Run the script from your Maven project's root."
    }

    [xml]$pom = Get-Content "pom.xml"
    $project = $pom.project
    
    $artifactId = $project.artifactId
    $version = $project.version

    if (-not $artifactId -or -not $version) {
        throw "Could not extract artifactId or version from pom.xml."
    }

    return @{ Name = $artifactId; Version = $version }
}

# Detects the current OS (Windows, Linux, macOS)
function Resolve-Platform {
    if ($IsWindows) { return "Windows" }
    elseif ($IsLinux) { return "Linux" }
    elseif ($IsMacOS) { return "MacOS" }
    else { throw "Unsupported OS platform." }
}

# Determines the correct icon file based on OS and user-provided base name
function Find-Icon {
    param ($platform, $iconPrefix)
    $iconDir = "src/main/resources/icons"
    $ext = switch ($platform) {
        "Windows" { ".ico" }
        "Linux"   { ".png" }
        "MacOS"   { ".icns" }
    }

    $iconPath = Join-Path $iconDir ($iconPrefix + $ext)
    if (-not (Test-Path $iconPath)) {
        Write-Warning "Icon file not found: $iconPath. jpackage will use default icon."
        return $null
    }
    return $iconPath
}

# Verifies that a required tool is installed and available in the PATH
function Confirm-Installed {
    param ($tool, $errorMessage)
    try {
        & $tool --version | Out-Null
    } catch {
        throw $errorMessage
    }
}

# Finds the fat JAR created by Maven Assembly plugin
function Find-FatJar {
    $jar = Get-ChildItem -Path target -Filter "*-jar-with-dependencies.jar" -Recurse -File | Select-Object -First 1
    if (-not $jar) {
        throw "Fat JAR not found in target/. Ensure Maven Assembly plugin is configured."
    }
    return $jar.Name
}

# Build the project
function Build-Project {
    Write-Host "`nBuilding project with Maven...`n" -ForegroundColor Green
    mvn clean package
    if ($LASTEXITCODE -ne 0) {
        throw "Maven build failed."
    }
}

function Resolve-OutputDir {
    if ($OutputDir -eq ".") {
        return (Get-Location).Path
    }
    return $OutputDir
}

# Constructs and executes the jpackage command based on platform and inputs
function Invoke-JPackage {
    param ($platform, $metadata, $jarName, $mainClass, $iconPath, $licenseFile, $outputDir, $vendor, $description)

    Write-Host "`nPackaging with jpackage..." -ForegroundColor Green
    $arguments = @(
        "--name", $metadata.Name,
        "--app-version", $metadata.Version,
        "--input", "target",
        "--main-jar", $jarName,
        "--main-class", $mainClass,
        "--dest", $outputDir,
        "--vendor", $vendor,
        "--description", "$description",
        "--license-file", $licenseFile
    )

    if ($iconPath) { $arguments += @("--icon", $iconPath) }

    switch ($platform) {
        "Windows" {
            $arguments += @("--win-per-user-install", "--win-shortcut-prompt", "--win-dir-chooser", "--win-menu")
        }
        "Linux" {
            $arguments += @("--linux-shortcut", "--linux-package-name", $metadata.Name.ToLower())
        }
        "MacOS" {
            $arguments += @("--mac-package-name", $metadata.Name)
        }
    }

    jpackage @arguments
    if ($LASTEXITCODE -ne 0) {
        throw "jpackage failed with exit code $LASTEXITCODE."
    }
}

# === Main Execution Flow ===

if (-not $MainClass) {
    Write-Error "No -MainClass specified. Please provide it explicitly."
    exit 1
}

$metadata = Get-ProjectMetadata
$platform = Resolve-Platform

Confirm-Installed -tool "mvn" -errorMessage "Maven is not installed or not in PATH."
Confirm-Installed -tool "jpackage" -errorMessage "jpackage (part of JDK) is not available in PATH."

Build-Project

$jarName = Find-FatJar

$iconPath = Find-Icon -platform $platform -iconPrefix $IconPrefix

Invoke-JPackage -platform $platform -metadata $metadata -jarName $jarName -mainClass $MainClass -iconPath $iconPath -licenseFile $LicenseFile -outputDir $OutputDir -vendor $VendorName -description $Description

$outputPath = Resolve-OutputDir
Write-Host "Package created successfully in '$outputPath'." -ForegroundColor Blue
