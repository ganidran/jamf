#!/bin/bash
#
# Downloads and installs Spotify for the current architecture (Apple Silicon
# or Intel) from the official DMG, then cleans up the mount and temp file.

###########################
#### SPOTIFY INSTALLER ####
###########################

# Set download URL by architecture.
if [[ "$(uname -p)" == "arm" ]]; then
    echo "Apple Silicon Mac"
    spotifyURL="https://download.scdn.co/SpotifyARM64.dmg"
else
    echo "Intel Mac"
    spotifyURL="https://download.scdn.co/Spotify.dmg"
fi

# Download DMG, mount, copy app to /Applications, set permissions, unmount, remove DMG.
curl -L "$spotifyURL" -o /tmp/spotify.dmg
hdiutil attach /tmp/spotify.dmg
cp -R /Volumes/Spotify/Spotify.app /Applications/
chown -R root:wheel /Applications/Spotify.app
chmod -R 755 /Applications/Spotify.app
hdiutil detach /Volumes/Spotify/
rm /tmp/spotify.dmg

echo "Finished installing $(uname -p) version of Spotify"
exit 0
