git submodule update --init --recursive
git submodule update --recursive --remote
cp user.js/{updater.sh,prefsCleaner.sh,user.js} .
cp VerticalFox/{windows,sideberry} .
mv windows chrome
