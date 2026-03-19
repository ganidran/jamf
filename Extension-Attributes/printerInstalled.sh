#!/bin/bash
#
# Jamf extension attribute: reports whether a printer with the configured
# IP address is installed (lpstat -v). Change printerIP as needed.

# IP of the printer to check.
printerIP="1.2.3.4"

# Check if that printer appears in lpstat -v.
if lpstat -v | grep -q "$printerIP"; then
    result="Printer is installed"
else
    result="Printer is not installed"
fi

echo "<result>$result</result>"
