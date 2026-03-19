#!/bin/bash
#
# Outputs the major macOS version (e.g. 13) and echoes whether it is >= 13
# or less than 13, for use in Jamf policies or extension attributes.

# Get major version (first component of product version).
majorVersion=$(sw_vers -productVersion | cut -d '.' -f1)
echo "$majorVersion"

# Report whether OS is 13 or greater.
if [[ "$majorVersion" -ge 13 ]]; then
  echo "OS version is 13 or greater"
else
  echo "OS version is less than 13"
fi
