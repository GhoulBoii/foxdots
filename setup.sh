git submodule update --init --recursive
git submodule update --recursive --remote
cp userjs/{updater.sh,prefsCleaner.sh,user.js} .
cp VerticalFox/{windows,sideberry} .
mv windows chrome
