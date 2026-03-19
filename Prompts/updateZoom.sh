#!/bin/bash
#
# Prompts the user via swiftDialog to update Zoom; if they accept, runs the
# Jamf policy to update Zoom and shows completion.

###########################
##### SET VARIABLES #######
###########################

dialogPath="/usr/local/bin/dialog"
dialogTitle="Zoom Update"
dialogButton1=""
dialogButton2=""
dialogMessage=""
dialogTimer="900"

###########################
###### DIALOG CHECK #######
###########################

# Ensure swiftDialog is installed before showing prompts.
if [ -e "$dialogPath" ]; then
    echo "swiftDialog exists. Proceeding..."
else
    echo "swiftDialog does not exist. Installing..."
    jamf policy -event install-swiftdialog
    sleep 1
fi

###########################
## MAIN DIALOG FUNCTION ###
###########################

# Show dialog with optional second button; return exit code.
promptUser(){
	if [[ "${#1}" -ge 1 ]]; then
		button2=("--button2text" "${dialogButton2}")
	fi
	"${dialogPath}" \
		--title "${dialogTitle}" \
		--message "${dialogMessage}" \
		--timer "${dialogTimer}" \
		--button1text "${dialogButton1}" \
		"${button2[@]}" \
		--hidetimerbar \
		--ontop \
		--width 600 --height 300 \
		--moveable \
		--messagefont size=16 \
		--messageposition center \
		--icon /Applications/zoom.us.app/Contents/Resources/ZPLogo.icns
	echo "$?"
}

# Ask user to update; on Yes run policy and show progress/success.
dialogMessage="Hello! This is your IT Team! \n\nThere is a required Zoom update scheduled for your computer. The update will take approximately 5 minutes and it will close any existing Zoom apps. \n\nWould you like to update now?"
dialogButton1="Yes. Update"
dialogButton2="No. Exit"
dialogResponse=$(promptUser "1")
echo "$dialogResponse"
if [ "$dialogResponse" == "2" ]; then
	exit 1
else
	echo "Updating Zoom..."
	dialogMessage="Please wait while Zoom is updated..."
	dialogButton1="OK"
	dialogTimer="30"
	promptUser
	jamf policy -event updatezoomit
	dialogMessage="The Zoom update is complete!"
	promptUser
fi

exit 0
