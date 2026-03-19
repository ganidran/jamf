#!/bin/bash
#
# Downloads and installs Notion for the current architecture (Apple Silicon
# or Intel) from the official DMG, then cleans up the mount and temp file.

###########################
#### NOTION INSTALLER #####
###########################

# Set download URL by architecture.
if [[ "$(uname -p)" == "arm" ]]; then
    echo "Apple Silicon Mac"
    notionURL="https://www.notion.so/desktop/apple-silicon/download"
else
    echo "Intel Mac"
    notionURL="https://www.notion.so/desktop/mac/download"
fi

# Download DMG, mount, copy app to /Applications, set permissions, unmount, remove DMG.
curl -L "$notionURL" -o /tmp/notion.dmg
hdiutil attach /tmp/notion.dmg
cp -R "/Volumes/Notion/Notion.app" /Applications/
chown -R root:wheel "/Applications/Notion.app"
chmod -R 775 "/Applications/Notion.app"
hdiutil detach "/Volumes/Notion/"
rm /tmp/notion.dmg

echo "Finished installing $(uname -p) version of Notion"
exit 0
