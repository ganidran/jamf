#!/bin/bash
#
# Removes 1Password 7 (app and support/preference/container data) if present,
# then downloads and installs the latest 1Password pkg from AgileBits and
# runs jamf recon.

###########################
##### SET VARIABLES #######
###########################

supportFolder="$HOME/Library/Application Support/"
preferencesFolder="$HOME/Library/Preferences/"
containersFolder="$HOME/Library/Containers/"
groupContainersFolder="$HOME/Library/Group Containers/"
downloadURL="https://downloads.1password.com/mac/1Password.pkg"
outputFile="1Password.pkg"

###########################
##### DO THE THINGS #######
###########################

# If 1Password 7 exists, quit it and remove app and related folders/files.
if [ -e /Applications/1Password\ 7.app ]; then
    echo "1Password 7 Exists, removing..."
    osascript -e 'quit app "1Password 7"'
    deleteFolder() {
        if [ -d "$1" ]; then
            rm -rf "$1"
        fi
    }
    deleteFile() {
        if [ -e "$1" ]; then
            rm -f "$1"
        fi
    }
    deleteFolder "${supportFolder}1Password*"
    deleteFile "${preferencesFolder}com.agilebits*"
    deleteFolder "${containersFolder}com.agilebits*"
    deleteFolder "${containersFolder}1Password*"
    deleteFolder "${groupContainersFolder}2BUA8C4S2C.com.agilebits*"
    deleteFolder "${groupContainersFolder}2BUA8C4S2C.com.1password*"
else
    echo "1Password 7 does not exist. Continuing..."
fi

# Download and install latest 1Password pkg.
echo "Installing 1Password package..."
downloadURL="https://downloads.1password.com/mac/1Password.pkg"
outputFile="/tmp/1Password.pkg"
curl -o "$outputFile" "$downloadURL" &
curlPID=$!
wait $curlPID
sudo installer -pkg "$outputFile" -target /

if [ $? -eq 0 ]; then
    echo "Installation completed successfully."
else
    echo "Installation failed."
fi

rm -f "$outputFile"
jamf recon
exit 0
