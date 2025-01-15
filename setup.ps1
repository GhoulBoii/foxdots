# Prompt for Firefox profile name
Write-Host "Enter name of the Firefox profile: " -ForegroundColor Green -NoNewline
$name = Read-Host

# Read JSON configuration file
$jsonContent = Get-Content -Raw -Path "config.json" | ConvertFrom-Json
$addonList = $jsonContent.addonlist -split ','

# Constants for paths
$firefoxProfilePath = "$env:APPDATA\Mozilla\Firefox"
$profilesIniPath = "$firefoxProfilePath\profiles.ini"
$mozillaAddonURL = "https://addons.mozilla.org"

function Create-Profile {
    Write-Host "Creating Profile..." -ForegroundColor Green

    # Create the Firefox profile
    Start-Process "firefox" -ArgumentList "-CreateProfile $name"
    Start-Sleep -Seconds 1  # Wait for Firefox to update profile.ini

    # Find the newly created profile directory
    $folder = (Get-Content $profilesIniPath | Select-String -Pattern "Path=.*$name$" | ForEach-Object { $_ -replace 'Path=', '' })
    $profileDir = Join-Path -Path $firefoxProfilePath "$folder"

    # Set working directory to profile folder
    Set-Location -Path $profileDir
    Write-Host "Profile Creation Finished" -ForegroundColor Green
}

function Init-GitRepo {
    Write-Host "Initializing Git Repository..." -ForegroundColor Green

    # Initialize the Git repository and fetch updates
    git init
    git remote add origin https://github.com/ghoulboii/firefox
    git fetch
    git checkout origin/master -ft
    git submodule update --init --recursive --remote

    # Copy necessary files
    robocopy userjs . user.js prefsCleaner.bat updater.bat
    robocopy VerticalFox\windows\ chrome
    robocopy VerticalFox\sidebery\ sidebery

    # Run updater script
    .\updater.bat -unattended

    Write-Host "Git Repository Initialized" -ForegroundColor Green
}

function Download-Addons {
    Write-Host "Downloading Addons..." -ForegroundColor Green

    # Create temporary folder for downloading add-ons
    $addonTmpDir = New-Item -ItemType Directory -Path "$env:TEMP\addon" -Force

    foreach ($addon in $addonList) {
        $addon = $addon.Trim()

        Write-Host "Installing addon: $addon" -ForegroundColor Green

        # Get addon download URL
        $addonPageContent = Invoke-WebRequest -Uri "$mozillaAddonURL/en-US/firefox/addon/$addon/" -UseBasicParsing
        $addonDownloadURL = $addonPageContent.Content | Select-String -Pattern "$mozillaAddonURL/firefox/downloads/file/[^`"]*" | ForEach-Object { $_.Value }

        # Download and extract the add-on
        $addonFileName = $addonDownloadURL -split '/' | Select-Object -Last 1
        $addonDownloadPath = Join-Path -Path $addonTmpDir.FullName -ChildPath $addonFileName

        Invoke-WebRequest -Uri $addonDownloadURL -OutFile $addonDownloadPath
        $addonExtractDir = Join-Path -Path $addonTmpDir.FullName -ChildPath "${addonFileName}folder"
        Expand-Archive -Path $addonDownloadPath -DestinationPath $addonExtractDir -Force

        # Extract addon ID and move to profile extensions folder
        $addonId = (Select-String -Path "$addonExtractDir/manifest.json" -Pattern '"id"\s*:\s*"([^"]*)"' -Raw | ForEach-Object { $_ -replace '\s*"id":\s*"([^"]*)"', '$1' }).Trim()

        # Ensure extensions directory exists and move the add-on
        $extensionsDir = Join-Path -Path $profileDir -ChildPath "extensions"
        New-Item -ItemType Directory -Path $extensionsDir -ErrorAction SilentlyContinue

        Move-Item -Path "$addonTmpDir\$addonFileName" -Destination "$extensionsDir\$addonId.xpi" -Force
    }

    Write-Host "Addons Installed" -ForegroundColor Green
}

# Run the functions
Create-Profile
Init-GitRepo
Download-Addons
