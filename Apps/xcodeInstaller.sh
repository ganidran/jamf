#!/bin/bash
#
# Installs Xcode from a Jamf-cached .xip (or triggers cache), unpacks with
# unxip, moves to Applications, sets permissions and developer mode, accepts
# license, installs component pkgs, then renames to Xcode.app. Uses swiftDialog
# for progress.

# Modified from James Smith's guide: https://smithjw.me/posts/2022-05-20-installing-xcode-xip/.

###########################
##### SET VARIABLES ######
###########################

xcodeVersion="$4"
xcodeTrigger="$5"
xcodeName="Xcode_${xcodeVersion}"
xcodeXipCache="/Library/Application Support/JAMF/Waiting Room/${xcodeName}.xip.pkg"
xcodeXipPath="/private/var/tmp/${xcodeName}.xip"
unxip="/private/var/tmp/unxip"

logFolder="/private/var/log"
logName="enrolment.log"
jamfBinary="/usr/local/bin/jamf"
dialogPath="/usr/local/bin/dialog"
dialogCommandFile="/var/tmp/dialog.log"
dialogIcon="https://developer.apple.com/assets/elements/icons/xcode-12/xcode-12-256x256.png"
dialogInitialTitle="Company IT - Xcode Installer"

###########################
###### DIALOG STEPS #######
###########################

dialogSteps=(
    "\"Downloading Xcode\""
    "\"Unpacking Xcode\""
    "\"Moving Xcode into Place\""
    "\"Setting Permissions\""
    "\"Installing Xcode Packages\""
)
dialogStepLength="${#dialogSteps[@]}"
dialogStep=0

dialogCmd=(
    "--title \"$dialogInitialTitle\""
    "--icon \"$dialogIcon\""
    "--position topleft"
    "--moveable"
    "--message \" \""
    "--small"
    "--position centre"
    "${dialogSteps[@]/#/--listitem }"
)

###########################
##### SET FUNCTIONS #######
###########################

echoLogger() {
    logFolder="${logFolder:=/private/var/log}"
    logName="${logName:=log.log}"
    mkdir -p $logFolder
    echo -e "$(date) - $1" | tee -a $logFolder/$logName
}

dialogUpdate() {
    echoLogger "Dialog: $1"
    echo "$1" >> "$dialogCommandFile"
}

dialogFinalise() {
    dialogUpdate "progresstext: Xcode Install Complete"
    sleep 1
    dialogUpdate "quit:"
    sleep 1
    jamf recon
    exit 0
}

###########################
###### DO THE THINGS ######
###########################

if [ ! -f "$dialogPath" ]; then
    jamf policy -event install-swiftdialog
fi
rm "$dialogCommandFile"
eval "$dialogPath" "${dialogCmd[*]}" & sleep 1

osascript -e 'quit app "Company Self Service"'

for (( i=0; i<dialogStepLength; i++ )); do
    dialogUpdate "listitem: index: $i, status: pending"
done

# Cache or move .xip from Waiting Room to /private/var/tmp.
if [ -f "${xcodeXipCache}" ]; then
    mv "${xcodeXipCache}" "${xcodeXipPath}"
    rm "${xcodeXipCache}.cache.xml"
    dialogUpdate "listitem: index: $((dialogStep++)), status: success"
else
    dialogUpdate "listitem: index: $((dialogStep)), status: wait"
    echoLogger "${xcodeName}.xip is not cached in waiting room, caching now"
    "$jamfBinary" policy -event "${xcodeTrigger}"
    mv "${xcodeXipCache}" "${xcodeXipPath}"
    rm "${xcodeXipCache}.cache.xml"
    dialogUpdate "listitem: index: $((dialogStep++)), status: success"
fi

# Unpack .xip and remove archive.
dialogUpdate "listitem: index: $((dialogStep)), status: wait"
echoLogger "Expanding ${xcodeXipPath}"
mkdir -p "/private/var/tmp"
$unxip "${xcodeXipPath}" "/private/var/tmp"
echoLogger "Removing ${xcodeXipPath}"
rm "${xcodeXipPath}"
dialogUpdate "listitem: index: $((dialogStep++)), status: success"

# Move Xcode.app and clear quarantine.
dialogUpdate "listitem: index: $((dialogStep)), status: wait"
echoLogger "Moving Xcode into Applications..."
mv "/private/var/tmp/Xcode.app" "/Applications/${xcodeName}.app"
xattr -r -d com.apple.quarantine "/Applications/${xcodeName}.app"
dialogUpdate "listitem: index: $((dialogStep++)), status: success"

# Developer group, DevToolsSecurity, xcode-select, accept license.
dialogUpdate "listitem: index: $((dialogStep)), status: wait"
echoLogger "Ensure everyone is a member of 'developer' group"
/usr/sbin/dseditgroup -o edit -a everyone -t group _developer
echoLogger "Enable Developer Mode"
/usr/sbin/DevToolsSecurity -enable
echoLogger "Switch to new Xcode Version"
/usr/bin/xcode-select -s "/Applications/${xcodeName}.app"
echoLogger "Accept the license"
"/Applications/${xcodeName}.app/Contents/Developer/usr/bin/xcodebuild" -license accept
dialogUpdate "listitem: index: $((dialogStep++)), status: success"

# Install component packages.
dialogUpdate "listitem: index: $((dialogStep)), status: wait"
for xcodePackage in $(/bin/ls /Applications/"${xcodeName}".app/Contents/Resources/Packages/*.pkg); do
    /usr/sbin/installer -pkg "$xcodePackage" -target /
done

# Rename to Xcode.app and finalise dialog.
osascript -e 'quit app "Xcode"'
sleep 1
if [[ -d /Applications/${xcodeName}.app ]]; then
    echo "Renaming Xcode"
    mv /Applications/"${xcodeName}.app" /Applications/Xcode.app
fi
dialogUpdate "listitem: index: $((dialogStep++)), status: success"

sleep 2
dialogFinalise
