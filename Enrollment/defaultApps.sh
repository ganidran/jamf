#!/bin/bash
#
# Sets the default handler for HTTP/HTTPS/HTML and mailto to Jamf-supplied
# browser and email agents by updating the current user's Launch Services
# plist and resetting the LS database.

# Jamf Pro parameters: browser and email agent bundle IDs.
browserAgentString="$4"
emailAgentString="$5"

# Resolve logged-in user and Launch Services plist path.
loggedInUser=$(/usr/bin/stat -f%Su "/dev/console")
loggedInUserHome=$(/usr/bin/dscl . -read "/Users/$loggedInUser" NFSHomeDirectory | /usr/bin/awk '{print $NF}')
launchServicesPlistFolder="$loggedInUserHome/Library/Preferences/com.apple.LaunchServices"
launchServicesPlist="$launchServicesPlistFolder/com.apple.launchservices.secure.plist"
plistbuddyPath="/usr/libexec/PlistBuddy"
plistbuddyPreferences=(
  "Add :LSHandlers:0:LSHandlerRoleAll string $browserAgentString"
  "Add :LSHandlers:0:LSHandlerURLScheme string http"
  "Add :LSHandlers:1:LSHandlerRoleAll string $browserAgentString"
  "Add :LSHandlers:1:LSHandlerURLScheme string https"
  "Add :LSHandlers:2:LSHandlerRoleViewer string $browserAgentString"
  "Add :LSHandlers:2:LSHandlerContentType string public.html"
  "Add :LSHandlers:3:LSHandlerRoleViewer string $browserAgentString"
  "Add :LSHandlers:3:LSHandlerContentType string public.url"
  "Add :LSHandlers:4:LSHandlerRoleViewer string $browserAgentString"
  "Add :LSHandlers:4:LSHandlerContentType string public.xhtml"
  "Add :LSHandlers:5:LSHandlerRoleAll string $emailAgentString"
  "Add :LSHandlers:5:LSHandlerURLScheme string mailto"
)
lsregisterPath="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"

# Exit if any required Jamf Pro arguments are undefined.
function checkJamfProArguments {
  jamfProArguments=(
    "$browserAgentString"
    "$emailAgentString"
  )
  for argument in "${jamfProArguments[@]}"; do
    if [[ -z "$argument" ]]; then
      echo "ERROR: Undefined Jamf Pro argument, unable to proceed."
      exit 74
    fi
  done
}
checkJamfProArguments

# Clear or create LSHandlers in plist.
if [[ -e "$launchServicesPlist" ]]; then
  "$plistbuddyPath" -c "Delete :LSHandlers" "$launchServicesPlist"
  echo "Reset LSHandlers array from $launchServicesPlist."
else
  /bin/mkdir -p "$launchServicesPlistFolder"
  "$plistbuddyPath" -c "Save" "$launchServicesPlist"
  echo "Created $launchServicesPlist."
fi

# Add new LSHandlers array and each handler entry.
"$plistbuddyPath" -c "Add :LSHandlers array" "$launchServicesPlist"
echo "Initialized LSHandlers array."
for plistbuddyCommand in "${plistbuddyPreferences[@]}"; do
  "$plistbuddyPath" -c "$plistbuddyCommand" "$launchServicesPlist"
  if [[ "$plistbuddyCommand" = *"$browserAgentString"* ]] || [[ "$plistbuddyCommand" = *"$emailAgentString"* ]]; then
    arrayEntry=$(echo "$plistbuddyCommand" | /usr/bin/awk -F: '{print $2 ":" $3 ":" $4}' | /usr/bin/sed 's/ .*//')
    prefLabel=$(echo "$plistbuddyCommand" | /usr/bin/awk '{print $4}')
    echo "Set $arrayEntry to $prefLabel."
  fi
done

# Restore ownership and reset Launch Services database.
/usr/sbin/chown -R "$loggedInUser" "$launchServicesPlistFolder"
echo "Fixed permissions on $launchServicesPlistFolder."
"$lsregisterPath" -kill -r -domain local -domain system -domain user
echo "Reset Launch Services database. A restart may also be required for these new default client changes to take effect."

exit 0
