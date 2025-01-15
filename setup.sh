#!/bin/sh

input_profile_name() {
  echo -n "Enter name of the Firefox profile: "
  read name
  echo "$name"
}

create_profile() {
  declare -r name="$1"
  echo "Creating Profile"
  firefox -CreateProfile "$name"

  # Get the folder path of the newly created profile
  local folder=$(sed -n "/Path=.*\.$name$/ s/.*=//p" ~/.mozilla/firefox/profiles.ini)
  local path="/home/$(whoami)/.mozilla/firefox/$folder"

  # Change to profile directory
  cd "$path" || exit 1
  echo "Profile Creation Finished"
  echo "$path"
}

initialize_git_repo() {
  echo "Initializing Git Repo"
  git init
  git remote add origin https://github.com/ghoulboii/firefox
  git fetch
  git checkout origin/master -ft
  git submodule update --init --recursive --remote

  cp userjs/updater.sh .
  cp userjs/prefsCleaner.sh .
  cp userjs/user.js .
  cp -r VerticalFox/windows .
  cp -r VerticalFox/sidebery .

  mv windows chrome

  ./updater.sh -s
  echo "Git Repo Initialized"
}

install_addons() {
  declare -r path="$1"
  declare -r addons_list="$2"
  declare -r mozillaurl="https://addons.mozilla.org"
  echo "Downloading Addons"

  # Create a temporary directory for downloading addons
  addontmp=$(mktemp -d)
  trap "rm -fr $addontmp" HUP INT QUIT TERM PWR EXIT

  mkdir -p "$path/extensions/"

  # Iterate over the addon list
  IFS=','  # Use comma as delimiter for addon list
  for addon in $addons_list; do
    addon=$(echo "$addon" | tr -d ' ')  # Remove any spaces

    echo "Installing $addon"

    # Get the download URL for the addon
    addonurl=$(curl --silent "$mozillaurl/en-US/firefox/addon/$addon/" | grep -o "$mozillaurl/firefox/downloads/file/[^\"]*")
    file="${addonurl##*/}"

    # Download the addon
    curl -LOs "$addonurl" > "$addontmp/$file"

    # Extract the addon ID from the manifest.json
    id=$(unzip -p "$addontmp/$file" manifest.json | grep -o '"id": *"[^"]*' | sed 's/"id": *"//')

    # Move the downloaded addon to the profile extensions directory
    mv "$addontmp/$file" "$path/extensions/$id.xpi"
  done
  echo "Addons Installed"
}

main() {
  name=$(input_profile_name)
  # Read the extension list from config
  extension_list=$(grep -oP '"addons_list":\s*\[\K[^\]]+' config.json | tr -d ' ",')

  profile_path=$(create_profile "$name")
  initialize_git_repo
  install_addons "$profile_path" "$addons_list"
}

main
