# Read config file
$jsonContent = Get-Content -Raw -Path "config.json" | ConvertFrom-Json
Set-Variable addonsList -Option Constant -Value $jsonContent.addons_list -
$addonsList = $jsonContent.addons_list -split ','

function Create-Profile {
    Write-Host "Creating Profile..." -ForegroundColor Green

    Set-Variable firefoxProfilePath -Option Constant -Value "$env:APPDATA\Mozilla\Firefox"
    Set-Variable profilesIniPath -Option Constant -Value "$firefoxProfilePath\profiles.ini"

    Write-Host "Enter name of the firefox profile: " -ForegroundColor Green -NoNewline
    $name = Read-Host
    Start-Process "firefox" -ArgumentList "-CreateProfile $name"
    Start-Sleep -Seconds 1  # Wait for Firefox to update profile.ini

    # Find and cd into the new profile
    $folder = (Get-Content $profilesIniPath | Select-String -Pattern "Path=.*$name$" | ForEach-Object { $_ -replace 'Path=', '' })
    $profileDir = Join-Path -Path $firefoxProfilePath "$folder"
    Set-Location -Path $profileDir

    Write-Host "Profile Creation Finished" -ForegroundColor Green
    return $profileDir
}

function Init-GitRepo {
    Write-Host "Initializing Git Repository..." -ForegroundColor Green

    # Initialize the Git repository and fetch updates
    git init
    git remote add origin https://github.com/ghoulboii/foxdots
    git fetch
    git checkout --force --track origin/master
    git submodule update --init --recursive --remote

    robocopy userjs . user.js prefsCleaner.bat updater.bat

    .\updater.bat -unattended

    Write-Host "Git Repository Initialized" -ForegroundColor Green
}

function Download-Addons {
    param (
        [string]$profileDir
    )
    Write-Host "Downloading Addons..." -ForegroundColor Green

    Set-Variable mozillaAddonURL -Option Constant -Value "https://addons.mozilla.org"
    $addonTmpDir = New-Item -ItemType Directory -Path "$env:TEMP\addon" -Force
    $extensionsDir = New-Item -ItemType Directory -Path "$profileDir\extensions" -ErrorAction SilentlyContinue

    foreach ($addon in $addonsList) {
        $addon = $addon.Trim()

        Write-Host "Installing addon: $addon" -ForegroundColor Green

        # Get addon download URL
        $addonPageContent = Invoke-WebRequest -Uri "$mozillaAddonURL/en-US/firefox/addon/$addon/" -UseBasicParsing
        $addonDownloadURL = $addonPageContent.Content | Select-String -Pattern "$mozillaAddonURL/firefox/downloads/file/[^`"]*" | Select-Object -ExpandProperty Matches | ForEach-Object { $_.Value }

        # Download and extract the add-on
        $addonFileName = $addonDownloadURL -split '/' | Select-Object -Last 1
        $addonDownloadPath = Join-Path -Path $addonTmpDir.FullName -ChildPath $addonFileName

        Invoke-WebRequest -Uri $addonDownloadURL -OutFile $addonDownloadPath
        $addonExtractDir = Join-Path -Path $addonTmpDir.FullName -ChildPath "${addonFileName}folder"
        Expand-Archive -Path $addonDownloadPath -DestinationPath $addonExtractDir -Force

        # Extract addon ID and move to profile extensions folder
        $addonId = (Select-String -Path "$addonExtractDir/manifest.json" -Pattern '"id"' -Raw | ForEach-Object { $_ -replace '\s*"id":\s*"([^"]*)"', '$1' }).Trim(',')
        Move-Item -Path "$addonTmpDir\$addonFileName" -Destination "$extensionsDir\$addonId.xpi" -Force
    }

    Write-Host "Addons Installed" -ForegroundColor Green
}

$profileDir = Create-Profile
Init-GitRepo
Download-Addons -profileDir $profileDir
