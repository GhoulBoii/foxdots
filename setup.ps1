$addonlist = @"
ublock-origin,
bitwarden-password-manager,
darkreader,
libredirect,
sidebery,
sponsorblock,
windscribe,
violentmonkey
"@

Write-Host "Enter name of the firefox profile: " -ForegroundColor Green -NoNewline
$name = Read-Host

Write-Host "Creating Profile" -ForegroundColor Green
Start-Process "firefox" -ArgumentList "-CreateProfile $name"
# Firefox does not update profile.ini fast enough so sleep is needed
Start-Sleep 1
$folder = (Get-Content "$env:APPDATA\Mozilla\Firefox\profiles.ini" | Select-String -Pattern "Path=.*$name$" | ForEach-Object { $_ -replace 'Path=', '' })
$dir = Join-Path -Path "$env:APPDATA/Mozilla/Firefox" "$folder"
Set-Location -Path "$dir"
Write-Host "Profile Creation Finished" -ForegroundColor Green

Write-Host "Initialising Git Repo" -ForegroundColor Green
git init
git remote add origin https://github.com/ghoulboii/firefox
git fetch
git checkout origin/master -ft
git submodule update --init --recursive --remote
robocopy userjs . user.js prefsCleaner.bat updater.bat
robocopy VerticalFox\windows\ chrome
robocopy VerticalFox\sidebery\ sidebery
.\updater.bat -unattended
Write-Host "Git Repo Initialised" -ForegroundColor Green

Write-Host "Downloading Addons" -ForegroundColor Green
$addontmp = New-Item -ItemType Directory -Path "$env:TEMP\addon" -Force
$mozillaurl = "https://addons.mozilla.org"
$addonlist -split ',' | ForEach-Object {
    $addon = $_.Trim()
    Write-Host "Installing $addon" -ForegroundColor Green
    $addonurl = (Invoke-WebRequest -Uri "$mozillaurl/en-US/firefox/addon/$addon/" -UseBasicParsing).Content | Select-String -Pattern "$mozillaurl/firefox/downloads/file/[^`"]*" | Select-Object -ExpandProperty Matches | ForEach-Object { $_.Value }
    $file = $addonurl -split '/' | Select-Object -Last 1
    Invoke-WebRequest -Uri $addonurl -OutFile "$addontmp\$file"
    Expand-Archive -Path "$addontmp\$file" -DestinationPath "$addontmp\${file}folder" -Force
    $id = (Select-String -Path "$addontmp/${file}folder/manifest.json" -Pattern '"id"' -Raw | ForEach-Object { $_ -replace '\s*"id":\s*"([^"]*)"', '$1' }).Trim(',')
    New-Item -ItemType Directory -Path "$dir\extensions" -ErrorAction SilentlyContinue > $null
    Move-Item -Path "$addontmp\$file" -Destination "$dir\extensions\$id.xpi" -Force
}
Write-Host "Addons Installed" -ForegroundColor Green

