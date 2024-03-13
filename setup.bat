@echo off

rem Initialize and update submodules recursively
git submodule update --init --recursive

rem Update submodules to their latest remote commits
git submodule update --recursive --remote

rem Copy files from user.js submodule
robocopy userjs . user.js prefsCleaner.bat updater.bat

rem Copy files from VerticalFox submodule
robocopy VerticalFox\windows\ chrome
robocopy VerticalFox\sidebery\ sidebery

