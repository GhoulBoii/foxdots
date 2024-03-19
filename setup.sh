#!/bin/sh

echo -n "Enter name of the firefox profile: " && read name
addonlist="ublock-origin,
bitwarden-password-manager,
darkreader,
sidebery,
sponsorblock,
windscribe,
violentmonkey"

echo "Creating Profile"
firefox -CreateProfile $name
folder=$(sed -n "/Path=.*.$name$/ s/.*=//p" ~/.mozilla/firefox/profiles.ini)
path="/home/$(whoami)/.mozilla/firefox/$folder"
cd $path
echo "Profile Creation Finished"

echo "Moving Files Around"
cp userjs/{updater.sh,prefsCleaner.sh,user.js} .
cp -r VerticalFox/{windows,sidebery} .
mv windows chrome
echo "Movement Finished"

echo "Downloading Addons"
addontmp="$(mktemp -d)"
trap "rm -fr $addontmp" HUP INT QUIT TERM PWR EXIT
mozillaurl="https://addons.mozilla.org"
IFS=$'\n,'
mkdir -p "$path/extensions/"
for addon in $addonlist; do
	echo "Installing $addon"
	addonurl="$(curl --silent "$mozillaurl/en-US/firefox/addon/${addon}/" | grep -o "$mozillaurl/firefox/downloads/file/[^\"]*")"
	file="${addonurl##*/}"
	curl -LOs "$addonurl" >"$addontmp/$file"
	id="$(unzip -p "$file" manifest.json | grep "\"id\"")"
	id="${id%\"*}"
	id="${id##*\"}"
	mv "$file" "$path/extensions/$id.xpi"
done
echo "Addons Installed"
