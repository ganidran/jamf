#!/bin/bash
#
# Sets the current user's account picture to a company-provided icon by
# replacing the JPEGPhoto in Directory Service with the configured image path.

###########################
###### SET VARIABLES ######
###########################

currentUser=$(stat -f "%Su" /dev/console)
userIcon="/usr/local/jamf/<icon-file-name>.png"

###########################
####### DO THE DEW ########
###########################

# Remove existing photo and set new one via dscl.
dscl . delete /Users/"$currentUser" JPEGPhoto
dscl . create Users/"$currentUser" Picture "$userIcon"
