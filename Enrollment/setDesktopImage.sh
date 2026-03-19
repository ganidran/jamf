#!/bin/bash
#
# Sets the desktop picture for the current user to a company image using
# desktoppr. Requires a package that installs the image and desktoppr binary.

# First requires a package to be deployed with the image along with desktoppr (https://github.com/scriptingosx/desktoppr)

###########################
###### SET VARIABLES ######
###########################

companyDesktop="/Library/Desktop Pictures/desktopImage.png"
desktoppr="/usr/local/bin/desktoppr"
loggedInUser=$(stat -f "%Su" /dev/console)
uid=$(id -u "$loggedInUser")

###########################
###### DO THE THINGS ######
###########################

launchctl asuser "$uid" "$desktoppr" "$companyDesktop"
sleep 1
rm -r /usr/local/bin/desktoppr
