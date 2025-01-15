# Read and parse configuration file
try {
    $jsonContent = Get-Content -Raw -Path "config.json" | ConvertFrom-Json
} catch {
    Write-Host "Error reading config.json. Please ensure the file exists and is valid JSON." -ForegroundColor Red
    exit 1
}

# Initialize constants from config
$ADDONS_LIST = $jsonContent.addons_list -split ',' | ForEach-Object { $_.Trim() }
$FIREFOX_PROFILE_PATH = if ($jsonContent.firefox_profile_path) {
    $jsonContent.firefox_profile_path
} else {
    "$env:APPDATA\Mozilla\Firefox"
}

function Create-Profile {
    <#
    .SYNOPSIS
        Creates a new Firefox profile and returns the profile directory path.
    .OUTPUTS
        System.String. The path to the newly created profile directory.
    #>
    Write-Host "Creating Profile..." -ForegroundColor Green
    $profilesIniPath = "$FIREFOX_PROFILE_PATH\profiles.ini"

    Write-Host "Enter name of the firefox profile: " -ForegroundColor Green -NoNewline
    $name = Read-Host
    Start-Process "firefox" -ArgumentList "-CreateProfile $name" -Wait

    # Find and cd into the new profile
    $profileContent = Get-Content $profilesIniPath -ErrorAction Stop
    $folder = $profileContent |
        Select-String -Pattern "Path=.*$name$" |
        ForEach-Object { $_ -replace 'Path=', '' } |
        Select-Object -First 1  # Added to handle multiple matches

    if (-not $folder) {
        Write-Host "Error: Could not find newly created profile." -ForegroundColor Red
        exit 1
    }

    $profileDir = Join-Path -Path $FIREFOX_PROFILE_PATH $folder
    Set-Location -Path $profileDir -ErrorAction Stop
    Write-Host "Profile Creation Finished" -ForegroundColor Green
    return $profileDir
}

function Init-GitRepo {
    <#
    .SYNOPSIS
        Initializes a Git repository with Firefox user preferences and configurations.
    #>
    Write-Host "Initializing Git Repository..." -ForegroundColor Green

    try {
        # Check if git is installed
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            throw "Git is not installed or not in PATH"
        }

        # Initialize repository and configure
        git init
        git remote add origin https://github.com/ghoulboii/foxdots

        # Fetch and checkout master branch
        git fetch --quiet
        git checkout --force --track origin/master

        # Update submodules
        git submodule update --init --recursive --remote

        # Copy necessary files
        $filesToCopy = @("user.js", "prefsCleaner.bat", "updater.bat")
        foreach ($file in $filesToCopy) {
            if (Test-Path "userjs\$file") {
                Copy-Item "userjs\$file" -Destination "." -Force
            }
        }

        # Run updater if it exists
        if (Test-Path ".\updater.bat") {
            .\updater.bat -unattended
        }

        Write-Host "Git Repository Initialized" -ForegroundColor Green
    } catch {
        Write-Host "Error during Git initialization: $_" -ForegroundColor Red
        exit 1
    }
}

function Download-Addons {
    <#
    .SYNOPSIS
        Downloads and installs Firefox addons from Mozilla's addon store.
    .PARAMETER profileDir
        The Firefox profile directory where addons should be installed.
    #>
    param (
        [Parameter(Mandatory=$true)]
        [string]$profileDir
    )
    Write-Host "Downloading Addons..." -ForegroundColor Green

    $MOZILLA_ADDON_URL = "https://addons.mozilla.org"
    $addonTmpDir = New-Item -ItemType Directory -Path "$env:TEMP\firefox_addons" -Force
    $extensionsDir = New-Item -ItemType Directory -Path "$profileDir\extensions"

    foreach ($addon in $ADDONS_LIST) {
        try {
            Write-Host "Installing addon: $addon" -ForegroundColor Green

            # Get addon download URL
            $addonPageUrl = "$MOZILLA_ADDON_URL/en-US/firefox/addon/$addon/"
            $addonPageContent = Invoke-WebRequest -Uri $addonPageUrl -UseBasicParsing
            $addonDownloadURL = $addonPageContent.Links |
                Where-Object { $_.href -match "/firefox/downloads/file/" } |
                Select-Object -First 1 -ExpandProperty href

            if (-not $addonDownloadURL) {
                throw "Could not find download URL for addon: $addon"
            }

            # Download and extract addon
            $addonFileName = Split-Path $addonDownloadURL -Leaf
            $addonDownloadPath = Join-Path -Path $addonTmpDir.FullName -ChildPath $addonFileName

            Invoke-WebRequest -Uri $addonDownloadURL -OutFile $addonDownloadPath
            $addonExtractDir = Join-Path -Path $addonTmpDir.FullName -ChildPath "${addon}_extracted"
            Expand-Archive -Path $addonDownloadPath -DestinationPath $addonExtractDir -Force

            # Get addon ID and install
            $manifestPath = Join-Path $addonExtractDir "manifest.json"
            if (-not (Test-Path $manifestPath)) {
                throw "manifest.json not found in addon package"
            }

            $manifestContent = Get-Content $manifestPath -Raw | ConvertFrom-Json

            # Handle both Manifest V2 and V3 addon ID locations
            $addonId = if ($manifestContent.applications -and $manifestContent.applications.gecko.id) {
                # Manifest V2
                $manifestContent.applications.gecko.id
            } elseif ($manifestContent.browser_specific_settings -and $manifestContent.browser_specific_settings.gecko.id) {
                # Manifest V3
                $manifestContent.browser_specific_settings.gecko.id
            } else {
                throw "Could not find addon ID in manifest (neither V2 nor V3 format)"
            }

            if (-not $addonId) {
                throw "Could not find addon ID in manifest"
            }

            Move-Item -Path $addonDownloadPath -Destination "$extensionsDir\$addonId.xpi" -Force

        } catch {
            Write-Host "Error installing addon $addon`: $_" -ForegroundColor Red
            continue
        }
    }

    # Cleanup
    Remove-Item -Path $addonTmpDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Addons Installation Completed" -ForegroundColor Green
}

# Main
try {
    $profileDir = Create-Profile
    Init-GitRepo
    Download-Addons -profileDir $profileDir
    Write-Host "Firefox profile setup completed successfully!" -ForegroundColor Green
} catch {
    Write-Host "An error occurred during profile setup: $_" -ForegroundColor Red
    exit 1
}
