#!/bin/bash
#
# Reports whether the device is compliant with Jamf (JSS) by running
# jamf checkJSSConnection and echoing compliant or not.

# Run Jamf compliance check and capture output.
complianceStatus=$(jamf checkJSSConnection)

# Echo result based on compliance message.
if [[ $complianceStatus == *"The system is compliant"* ]]; then
  echo "The device is compliant"
else
  echo "The device is not compliant"
fi
