#!/bin/bash
#
# Post-setup enrollment script: waits for Setup Assistant to finish, collects
# company email via swiftDialog, installs core apps and policies (EPP, Chrome,
# Kolide, Zoom), sets desktop/dock/user icon, runs jamf recon with username,
# then prompts for restart.

###########################
####### SETUP CHECK #######
###########################

# Wait for Setup Assistant to complete before proceeding.
while pgrep -x "Setup Assistant" > /dev/null; do
    sleep 5
done
echo "--Initial macOS setup complete.--"

###########################
###### SET VARIABLES ######
###########################

dialogPath="/usr/local/bin/dialog"
currentUser=$(stat -f "%Su" /dev/console)

###########################
#### GRAB USER'S NAME #####
###########################

userFull=$(dscl . -read /Users/"$currentUser" RealName | tr -d '\n' | sed 's/RealName: //')
userFirst=$(echo "$userFull" | cut -d " " -f 1)
echo "--Grabbing first name of logged in user: '$userFirst'--"

###########################
##### SYSTEM CHECKS #######
###########################

if [ -e "/usr/local/jamf/company-icon.png" ]; then
    echo "--Company images exist. Proceeding...--"
else
    echo "--Company images don't exist. Installing...--"
    jamf policy -event install-company-images
fi
if [ -e "$dialogPath" ]; then
    echo "--swiftDialog exists. Re-installing...--"
    jamf policy -event install-swiftdialog
else
    echo "--swiftDialog does not exist. Installing...--"
    jamf policy -event install-swiftdialog
fi
sleep 3

###########################
## DO ENROLLMENT THINGS ###
###########################

echo "----START----"

# Collect company email via full-screen dialog.
emailDialogResults=$("${dialogPath}" \
--blurscreen \
--quitkey l \
--title "Company Email Needed" \
--message "This computer needs to be registered to your Company email, please enter it below. If newly onboarding, please enter it exactly as it appears in your welcome email. Thank you! " \
--button1text "OK" \
--ontop \
--width 600 --height 300 \
--moveable \
--messageposition center \
--icon /Users/Shared/fun.png \
--textfield "Company Email",required,regex="^[a-zA-Z0-9._%+-]+@company\.com$",regexerror="Input must be a Company email address")
emailAddress=$(echo "$emailDialogResults" | awk -F' : ' '{print $2}')
echo "--User Company email entered--"
echo $emailAddress

# Show full-screen "Installing..." placeholder.
echo "--Placing fullscreen dialog window--"
$"$dialogPath" \
--blurscreen \
--quitkey l \
--width 600 --height 300 \
--button1text "Installing..." \
--button1disabled \
--title "W E L C O M E    T O    L E V E L" \
--message "Welcome to Company $userFirst! \n\nYour computer is downloading necessary policies and will restart once it's complete. \n\n**Please** plug in the charger to avoid the computer from shutting down." \
--messagefont size=18 \
--icon /usr/local/jamf/company-icon.png &
echo "--Finishing initial installions--"
sleep 120

# Install EPP if missing.
if [ -e /Applications/EndpointProtectorClient.app ]; then
    echo "--Endpoint Protector exists--"
else
    echo "--Endpoint Protector does not exist. Installing...--"
    jamf policy -event install_endpoint_protector
    sleep 0.5
fi

# Install Chrome if missing.
if [ -e /Applications/Google\ Chrome.app ]; then
    echo "--Google Chrome exists--"
else
    echo "--Google Chrome does not exist. Installing...--"
    jamf policy -event install_google_chrome
    sleep 0.5
fi

# Install Kolide if missing.
if [ -d /usr/local/kolide-k2 ]; then
    echo "--Kolide exists--"
else
    echo "--Kolide does not exist. Installing...--"
    jamf policy -event install-kolide
    sleep 0.5
fi

# Install Zoom if missing.
if [ -e /Applications/zoom.us.app ]; then
    echo "--Zoom exists--"
else
    echo "--Zoom does not exist. Installing...--"
    jamf policy -event installzoom
    sleep 0.5
fi

# Set desktop, default apps, dock, user icon via policies.
jamf policy -event set-desktop
sleep 0.5
echo "--Desktop set--"
jamf policy -event set-apps
sleep 0.5
echo "--Default apps set--"
jamf policy -event set-dock
sleep 0.5
echo "--Dock set--"
jamf policy -event set-user-icon
sleep 0.5
echo "--Dock set--"

# Send email to Jamf as username and run recon.
jamf recon -endUsername "$emailAddress"
echo "--Jamf username set--"

# Prompt restart; on Restart or timer, schedule restart and show countdown.
echo "--Prompting user to restart--"
$"$dialogPath" \
--width 600 --height 300 \
--button1text "Restart" \
--button2text "Onboarding" \
--ontop \
--title "Setup Complete" \
--timer 120 \
--message "Almost there $userFirst! Your computer has finished its setup and requires a restart. \n\nPlease restart your computer unless you're onboarding with IT." \
--icon /usr/local/jamf/company-icon.png
dialogResults=$?

if [ "$dialogResults" == "0" ]; then
    echo "--User chose to Restart. Restarting...--"
    shutdown -r +1 &
    $"$dialogPath" \
    --width 400 --height 150 \
    --hideicon \
    --ontop \
    --alignment center \
    --title "Restarting" \
    --timer 60 \
    --message "Your computer will restart in:" \ &
elif [ "$dialogResults" == "4" ]; then
    echo "--Timer finished without user input. Restarting...--"
    shutdown -r +1 &
    $"$dialogPath" \
    --width 400 --height 150 \
    --hideicon \
    --ontop \
    --alignment center \
    --title "Restarting" \
    --timer 60 \
    --message "Your computer will restart in:" \ &
else
    echo "--Restart aborted. User chose 'Onboarding'--"
    exit 0
fi

echo "----FIN----"
exit 0
