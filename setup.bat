@echo off

rem Initialize and update submodules recursively
git submodule update --init --recursive

rem Update submodules to their latest remote commits
git submodule update --recursive --remote

rem Copy files from user.js submodule
copy user.js\updater.sh .
copy user.js\prefsCleaner.sh .
copy user.js\user.js .

rem Copy files from VerticalFox submodule
copy VerticalFox\windows .
copy VerticalFox\sideberry .

rem Move the 'windows' directory to 'chrome'
move windows chrome
