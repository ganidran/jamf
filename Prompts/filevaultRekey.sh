#!/bin/bash
#
# Reissues the FileVault recovery key and escrows it via MDM. Prompts the
# logged-in user for their Mac password, validates FileVault status, then
# runs fdesetup changerecovery. Based on Elliot Jordan's jss-filevault-reissue.

# Modified script from Elliot Jordan's guide: https://github.com/homebysix/jss-filevault-reissue

###########################
##### SET VARIABLES #######
###########################

promptTitle="Attention Required!"
promptMessage="Howdy folks! Your Mac's FileVault encryption key needs to be escrowed by IT.

Click the Next button below, then enter your Mac's password when prompted."
forgotPwMessage="You made five incorrect password attempts.

Please contact IT for help with your Mac password."
successMessage="Thank you! Your FileVault key is updated."
failMessage="Sorry, an error occurred while escrowing your FileVault key. Please contact IT for help."

###########################
###### VALIDATIONS ########
###########################

exec 2>/dev/null
bailOut=false

# Require jamfHelper for user-facing prompts.
jamfHelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
if [[ ! -x "$jamfHelper" ]]; then
    reason="jamfHelper not found."
    bailOut=true
fi

# Require FileVault on and not in progress.
fvStatus="$(/usr/bin/fdesetup status)"
if /usr/bin/grep -q "Encryption in progress" <<< "$fvStatus"; then
    reason="FileVault encryption is in progress. Please run the script again when it finishes."
    bailOut=true
elif /usr/bin/grep -q "FileVault is Off" <<< "$fvStatus"; then
    reason="Encryption is not active."
    bailOut=true
elif ! /usr/bin/grep -q "FileVault is On" <<< "$fvStatus"; then
    reason="Unable to determine encryption status."
    bailOut=true
fi

# Require a logged-in, FileVault-authorized user.
currentUser=$(stat -f "%Su" /dev/console)
if [[ -z $currentUser || "$currentUser" == "loginwindow" || "$currentUser" == "root" ]]; then
    reason="No user is currently logged in."
    bailOut=true
else
    fvUsers="$(/usr/bin/fdesetup list)"
    if ! /usr/bin/grep -E -q "^${currentUser}," <<< "$fvUsers"; then
        reason="$currentUser is not on the list of FileVault enabled users: $fvUsers"
        bailOut=true
    fi
fi

###########################
##### MAIN PROCESS ########
###########################

# Ensure company logo exists for dialogs.
if [ -e "/usr/local/jamf/company-icon.png" ]; then
    echo "--Company images exist. Proceeding...--"
else
    echo "--Company images don't exist. Installing...--"
    jamf policy -event install-company-images
fi
companyLogo="/usr/local/jamf/company-icon.png"
logoPosix="$(/usr/bin/osascript -e 'return POSIX file "'"$companyLogo"'" as text')"
userId=$(/usr/bin/id -u "$currentUser")
lId=$userId
lMethod="asuser"

# If validation failed, show failure and exit.
if [[ "$bailOut" == "true" ]]; then
    echo "[ERROR]: $reason"
    launchctl "$lMethod" "$lId" sudo -u "$currentUser" "$jamfHelper" -windowType "utility" -icon "$companyLogo" -title "$promptTitle" -description "$failMessage: $reason" -button1 'OK' -defaultButton 1 -startlaunchd &>/dev/null &
    exit 1
fi

# Show pre-prompt message, then collect password with retries (max 5).
echo "Alerting user $currentUser about incoming password prompt..."
/bin/launchctl "$lMethod" "$lId" sudo -u "$currentUser" "$jamfHelper" -windowType "utility" -icon "$companyLogo" -title "$promptTitle" -description "$promptMessage" -button1 "Next" -defaultButton 1 -startlaunchd &>/dev/null &
echo "Prompting $currentUser for their Mac password..."
userPass="$(/bin/launchctl "$lMethod" "$lId" sudo -u "$currentUser" /usr/bin/osascript -e 'display dialog "Please enter the password you use to log in to your Mac:" default answer "" with title "'"${promptTitle//\"/\\\"}"'" giving up after 86400 with text buttons {"OK"} default button 1 with hidden answer with icon file "'"${logoPosix//\"/\\\"}"'"' -e 'return text returned of result')"
try=1
until /usr/bin/dscl /Search -authonly "$currentUser" "$userPass" &>/dev/null; do
    (( try++ ))
    echo "Prompting $currentUser for their Mac password (attempt $try)..."
    userPass="$(/bin/launchctl "$lMethod" "$lId" sudo -u "$currentUser" /usr/bin/osascript -e 'display dialog "Sorry, that password was incorrect. Please try again:" default answer "" with title "'"${promptTitle//\"/\\\"}"'" giving up after 86400 with text buttons {"OK"} default button 1 with hidden answer with icon file "'"${logoPosix//\"/\\\"}"'"' -e 'return text returned of result')"
    if (( try >= 5 )); then
        echo "[ERROR] Password prompt unsuccessful after 5 attempts. Displaying \"forgot password\" message..."
        /bin/launchctl "$lMethod" "$lId" sudo -u "$currentUser" "$jamfHelper" -windowType "utility" -icon "$companyLogo" -title "$promptTitle" -description "$forgotPwMessage" -button1 'OK' -defaultButton 1 -startlaunchd &>/dev/null &
        exit 1
    fi
done
echo "Successfully prompted for Mac password."

# Unload FDERecoveryAgent if loaded so key change can proceed.
if /bin/launchctl list | /usr/bin/grep -q "com.apple.security.FDERecoveryAgent"; then
    echo "Unloading FDERecoveryAgent LaunchDaemon..."
    /bin/launchctl unload /System/Library/LaunchDaemons/com.apple.security.FDERecoveryAgent.plist
fi
if pgrep -q "FDERecoveryAgent"; then
    echo "Stopping FDERecoveryAgent process..."
    killall "FDERecoveryAgent"
fi

# Escape XML special characters in password for plist.
userPass=${userPass//&/&amp;}
userPass=${userPass//</&lt;}
userPass=${userPass//>/&gt;}
userPass=${userPass//\"/&quot;}
userPass=${userPass//\'/&apos;}

# Record PRK modification time for 10.13 escrow check.
if [ -e "/var/db/FileVaultPRK.dat" ]; then
    echo "Found existing personal recovery key."
    prkMod=$(/usr/bin/stat -f "%Sm" -t "%s" "/var/db/FileVaultPRK.dat")
fi

# Run fdesetup changerecovery with user password.
echo "Issuing new recovery key..."
fdesetupOutput="$(/usr/bin/fdesetup changerecovery -norecoverykey -verbose -personal -inputplist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Username</key>
    <string>$currentUser</string>
    <key>Password</key>
    <string>$userPass</string>
</dict>
</plist>
EOF
)"
fdesetupResult=$?
unset userPass

# Check whether PRK was updated for escrow confirmation.
escrowStatus=1
if [ -e "/var/db/FileVaultPRK.dat" ]; then
    newPrkMod=$(/usr/bin/stat -f "%Sm" -t "%s" "/var/db/FileVaultPRK.dat")
    if [[ $newPrkMod -gt $prkMod ]]; then
        escrowStatus=0
        echo "Recovery key updated locally and available for collection via MDM. (This usually requires two 'jamf recon' runs to show as valid.)"
    else
        echo "[WARNING] The recovery key does not appear to have been updated locally."
    fi
fi

# Show success or failure dialog and exit.
if [[ $fdesetupResult -ne 0 ]]; then
    [[ -n "$fdesetupOutput" ]] && echo "$fdesetupOutput"
    echo "[WARNING] fdesetup exited with return code: $fdesetupResult."
    echo "See this page for a list of fdesetup exit codes and their meaning:"
    echo "https://developer.apple.com/legacy/library/documentation/Darwin/Reference/ManPages/man8/fdesetup.8.html"
    echo "Displaying \"failure\" message..."
    /bin/launchctl "$lMethod" "$lId" sudo -u "$currentUser" "$jamfHelper" -windowType "utility" -icon "$companyLogo" -title "$promptTitle" -description "$failMessage: fdesetup exited with code $fdesetupResult. Output: $fdesetupOutput" -button1 'OK' -defaultButton 1 -startlaunchd &>/dev/null &
elif [[ $escrowStatus -ne 0 ]]; then
    [[ -n "$fdesetupOutput" ]] && echo "$fdesetupOutput"
    echo "[WARNING] FileVault key was generated, but escrow cannot be confirmed. Please verify that the redirection profile is installed and the Mac is connected to the internet."
    echo "Displaying \"failure\" message..."
    /bin/launchctl "$lMethod" "$lId" sudo -u "$currentUser" "$jamfHelper" -windowType "utility" -icon "$companyLogo" -title "$promptTitle" -description "$failMessage: New key generated, but escrow did not occur." -button1 'OK' -defaultButton 1 -startlaunchd &>/dev/null &
else
    [[ -n "$fdesetupOutput" ]] && echo "$fdesetupOutput"
    echo "Displaying \"success\" message..."
    /bin/launchctl "$lMethod" "$lId" sudo -u "$currentUser" "$jamfHelper" -windowType "utility" -icon "$companyLogo" -title "$promptTitle" -description "$successMessage" -button1 'OK' -defaultButton 1 -startlaunchd &>/dev/null &
fi

###########################
#### INVENTORY CHECK ######
###########################

jamf recon
exit $fdesetupResult
