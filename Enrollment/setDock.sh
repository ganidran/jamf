#!/bin/bash
#
# Replaces the current user's dock plist with a company default (Monterey or
# Ventura based on OS), resets LaunchPad, and restarts the Dock.

###########################
###### SET VARIABLE ######
###########################

osVersion=$(sw_vers -productVersion)
loggedInUser=$(stat -f "%Su" /dev/console)
venturaDock="/usr/local/jamf/dock/com.apple.dock.v.plist"
montereyDock="/usr/local/jamf/dock/com.apple.dock.m.plist"
defaultDock="/usr/local/jamf/dock/com.apple.dock.plist"
dockPath="/Users/$loggedInUser/Library/Preferences"

###########################
##### DO THE THINGS ######
###########################

# Remove current dock prefs and copy OS-appropriate default.
defaults delete "$dockPath"/com.apple.dock.plist
sleep 0.5
if [[ "$osVersion" == "12."* ]]; then
    mv "$montereyDock" "$defaultDock"
    cp "$defaultDock" "$dockPath"
else
    mv "$venturaDock" "$defaultDock"
    cp "$defaultDock" "$dockPath"
fi
sleep 0.5

# Set ownership and refresh dock cache.
chown $loggedInUser "$dockPath"/com.apple.dock.plist
sleep 0.5
sudo -u $loggedInUser defaults read "$dockPath"/com.apple.dock.plist
sleep 0.5
killall Dock
sleep 10

# Reset LaunchPad and restart Dock again.
sudo -u $loggedInUser defaults write com.apple.dock ResetLaunchPad -bool true
sleep 0.5
killall Dock

# Remove staged dock plists.
rm -rf /usr/local/jamf/dock
