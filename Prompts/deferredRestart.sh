#!/bin/bash
#
# Prompts the user to restart with a configurable deferral limit. Compares
# last reboot date to a Jamf-supplied date; if reboot is needed, shows
# swiftDialog and tracks deferrals in a plist.

###########################
##### SET VARIABLES #######
###########################

# Jamf parameter 4: date string to compare (e.g. "Feb 28 10:15").
compareDate="$4"
lastReboot=$(last reboot | awk '/reboot/{print $4" "$5" "$6}' | head -1)
dialogPath="/usr/local/bin/dialog"
pBuddy="/usr/libexec/PlistBuddy"
deferralMaximum="3"
deferralPlist="/private/var/tmp/com.restart.deferrals.plist"

###########################
##### SYSTEM CHECKS #######
###########################

# Skip if last reboot is after the compare date.
if [[ "$lastReboot" > "$compareDate" ]]; then
    echo "The last reboot date is after $compareDate. Exiting..."
    exit 0
else
    echo "The last reboot date is on or before $compareDate. Prompting user to Restart..."
fi
if [ -e "$dialogPath" ]; then
    echo "swiftDialog exists. Proceeding..."
else
    echo "swiftDialog does not exist. Installing..."
    jamf policy -event install-swiftdialog
    sleep 1
fi

###########################
###### SET FUNCTIONS #######
###########################

# Set deferral count to 0 and restart.
function doTheThings() {
    echo "Restarting..."
    $pBuddy -c "Set DeferralCount 0" $deferralPlist
    sleep 2
    shutdown -r now
}

# Show dialog: Restart or Not Now.
function promptWithDeferral() {
    "$dialogPath" \
    --title "Time to Restart!" \
    --icon /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ToolbarAdvanced.icns \
    --message "IT here! Your computer received an important background update this week that requires a quick reboot. Would you like to do so now? \n\nIf so, please save all open documents first. If not please restart or shut down your computer at the end of your workday. \n\nYou can defer this request 3 times." \
    --button1text "Restart" \
    --button2text "Not Now" \
    --messageposition center \
    --moveable \
    --messagefont "size=15" \
    --width 600 --height 300
}

# No deferrals left; show final dialog with timer.
function promptNoDeferral() {
    "$dialogPath" \
    --title "Your computer is about to restart!" \
    --icon /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ToolbarAdvanced.icns \
    --message "Your computer needs to restart and no deferrals are left. \n\nIt will automatically reboot in 10 minutes or immediately by clicking 'Restart Now'. \n\nPlease make sure your laptop is plugged in, charging and save any open documents." \
    --moveable \
    --messageposition center \
    --timer 600 \
    --messagefont "size=15" \
    --button1text "Restart Now" \
    --width 600 --height 300
}

function logMessage() {
    echo "$(date): $*"
}

function cleanup() {
    logMessage "${2}"
    exit "${1}"
}

# Ensure plist is writable and deferral keys exist.
function verifyConfigFile() {
    if $pBuddy -c "Add Verification string Success" "$deferralPlist"  > /dev/null 2>&1; then
        $pBuddy -c "Delete Verification string Success" "$deferralPlist" > /dev/null 2>&1
    else
        cleanup 1 "ERROR: Cannot write to the deferral file: $deferralPlist"
    fi
    verifyDeferralValue "ActiveDeferral"
    verifyDeferralValue "DeferralCount"
}

function verifyDeferralValue() {
    if ! $pBuddy -c "Print :$1" "$deferralPlist"  > /dev/null 2>&1; then
        $pBuddy -c "Add :$1 integer 0" "$deferralPlist"  > /dev/null 2>&1
    fi
}

# Exit if there is an active deferral (future timestamp).
function checkForActiveDeferral() {
    currentDeferral=$($pBuddy -c "Print :ActiveDeferral" "$deferralPlist")
    if [ "$unixEpochTime" -lt "$currentDeferral" ]; then
        cleanup 0 "Active deferral found. Exiting"
    else
        logMessage "No active deferral."
        $pBuddy -c "Delete :HumanReadableDeferralDate" "$deferralPlist"  > /dev/null 2>&1
    fi
}

# Increment deferral count, show message, write plist, exit.
function executeDeferral() {
    deferralCount=$(( deferralCount + 1 ))
    "$dialogPath" \
    --title "Deferred" \
    --icon /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ToolbarAdvanced.icns \
    --message "Restart will be deferred. You have deferred $deferralCount of $deferralMaximum time(s)." \
    --button1text "OK" \
    --moveable \
    --messageposition center \
    --messagefont "size=15" \
    --width 500 --height 250
    $pBuddy -c "Set DeferralCount $deferralCount" $deferralPlist
    $pBuddy -c "Add :HumanReadableDeferralDate string" "$deferralPlist"  > /dev/null 2>&1
    cleanup 0 "User chose deferral $deferralCount of $deferralMaximum."
}

###########################
###### DO THE THINGS ######
###########################

verifyConfigFile
unixEpochTime=$(date +%s)
checkForActiveDeferral
deferralCount=$($pBuddy -c "Print :DeferralCount" $deferralPlist)

if [ "$deferralCount" -ge "$deferralMaximum" ]; then
    allowDeferral="false"
else
    allowDeferral="true"
fi

if [ "$allowDeferral" = "true" ]; then
    if promptWithDeferral; then
        doTheThings
        thingsExitCode=$?
        cleanup $thingsExitCode "Things were done. Exit code: $thingsExitCode"
    else
        executeDeferral
    fi
else
    promptNoDeferral
    doTheThings
    thingsExitCode=$?
    cleanup $thingsExitCode "Things were done. Exit code: $thingsExitCode"
fi
