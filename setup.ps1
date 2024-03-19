# Prompt user for input
$name = Read-Host -Prompt "Enter name of the firefox profile"

# Define addonlist
$addonlist = @"
ublock-origin,
bitwarden-password-manager,
darkreader,
sidebery,
sponsorblock,
windscribe,
violentmonkey
"@

# Creating Profile
echo "Creating Profile"
Start-Process "firefox" -ArgumentList "-CreateProfile $name"

# Determine profile folder
Start-Sleep 1
$folder = (Get-Content "$env:APPDATA\Mozilla\Firefox\profiles.ini" | Select-String -Pattern "Path=.*$name$" | ForEach-Object { $_ -replace 'Path=', '' })
$dir = Join-Path -Path "$env:APPDATA/Mozilla/Firefox" "$folder"
cd $dir
echo "Profile Creation Finished"

# Initialising Git Repo
echo "Initialising Git Repo"
git init
git remote add origin https://github.com/ghoulboii/firefox
git fetch
git checkout origin/master -ft
git submodule update --init --recursive
git submodule update --recursive --remote
robocopy userjs . user.js prefsCleaner.bat updater.bat
robocopy VerticalFox\windows\ chrome
robocopy VerticalFox\sidebery\ sidebery
echo "Git Repo Initialised"


# Downloading Addons
echo "Downloading Addons"
$addontmp = New-Item -ItemType Directory -Path "$env:TEMP\addon" -Force
$mozillaurl = "https://addons.mozilla.org"
$addonlist -split ',' | ForEach-Object {
    $addon = $_.Trim()
    echo "Installing $addon"
    $addonurl = (Invoke-WebRequest -Uri "$mozillaurl/en-US/firefox/addon/$addon/" -UseBasicParsing).Content | Select-String -Pattern "$mozillaurl/firefox/downloads/file/[^`"]*" | Select-Object -ExpandProperty Matches | ForEach-Object { $_.Value }
    $file = $addonurl -split '/' | Select-Object -Last 1
    Invoke-WebRequest -Uri $addonurl -OutFile "$addontmp\$file"
    Expand-Archive -Path "$addontmp\$file" -DestinationPath "$addontmp\${file}folder" -Force
    $id = (Select-String -Path "$addontmp/${file}folder/manifest.json" -Pattern '"id"' -Raw | ForEach-Object { $_ -replace '\s*"id":\s*"([^"]*)"', '$1' }).Trim(',')
    echo $id
    New-Item -ItemType Directory -Path "$dir\extensions" -ErrorAction SilentlyContinue
    Move-Item -Path "$addontmp\$file" -Destination "$dir\extensions\$id.xpi" -Force
}
echo "Addons Installed"

