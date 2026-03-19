#!/bin/bash
#
# Downloads the latest Google Chrome pkg from Google, installs it to the
# system, then removes the temp directory and package.

# Create temp dir and download Chrome pkg.
tempDir=$(mktemp -d)
cd "$tempDir"
chromeUrl="https://dl.google.com/chrome/mac/stable/accept_tos%3Dhttps%253A%252F%252Fwww.google.com%252Fintl%252Fen_ph%252Fchrome%252Fterms%252F%26_and_accept_tos%3Dhttps%253A%252F%252Fpolicies.google.com%252Fterms/googlechrome.pkg"
chromeFile="googlechrome.pkg"

echo "Downloading Google Chrome..."
curl -L -O "$chromeUrl"
echo "Installing Google Chrome..."
installer -pkg "$chromeFile" -target /
rm "$chromeFile"
cd -
rm -r "$tempDir"

echo "Google Chrome has been installed successfully."
