#!/bin/bash
#
# Jamf extension attribute: reports whether Homebrew is installed (Intel
# or Apple Silicon path).

# Check common Homebrew locations.
if command -v /usr/local/bin/brew &>/dev/null; then
  echo "<result>Installed</result>"
elif command -v /opt/homebrew/bin/brew &>/dev/null; then
  echo "<result>Installed</result>"
else
  echo "<result>Not Installed</result>"
fi
