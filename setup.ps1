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
$folder = (Get-Content "$env:APPDATA\Mozilla\Firefox\profiles.ini" | Select-String -Pattern "Path=.*$name$" | ForEach-Object { $_ -replace 'Path=', '' })
$dir = "$env:APPDATA/Mozilla/Firefox/$folder"
echo "The folder name is: $folder"
echo "The dir name is: $dir"
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
    $id = (Expand-Archive -Path "$addontmp\$file" -DestinationPath "manifest.json" | Get-Content | Select-String -Pattern '"id"' | ForEach-Object { $_ -replace '".*":', '' }).Trim()
    New-Item -ItemType Directory -Path "$dir\extensions" -Force
    Move-Item -Path "$addontmp\$file" -Destination "$dir\extensions\$id.xpi" -Force
}
echo "Addons Installed"

