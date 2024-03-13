@echo off

rem Initialize and update submodules recursively
git submodule update --init --recursive

rem Update submodules to their latest remote commits
git submodule update --recursive --remote

rem Copy files from user.js submodule
robocopy userjs\updater.bat .
robocopy userjs\prefsCleaner.bat .
robocopy userjs\user.js .

rem Copy files from VerticalFox submodule
robocopy VerticalFox\windows\ chrome
robocopy VerticalFox\sideberry\ sideberry

