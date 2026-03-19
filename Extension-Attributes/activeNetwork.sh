#!/bin/bash
#
# Jamf extension attribute: reports the list of active network interfaces
# (excluding utun), as port names (e.g. Wi-Fi, Ethernet).

###########################
##### SET VARIABLES #######
###########################

# Get active interfaces from scutil; then map to hardware port names.
activeNetwork=$(/usr/sbin/scutil --nwi | awk -F': ' '/Network interfaces:/{print $NF}')

###########################
##### DO THE THINGS #######
###########################

for device in $(printf '%s\n' "$activeNetwork"); do
	if [[ ! "$device" =~ "utun" ]]; then
		portName=$(/usr/sbin/networksetup -listallhardwareports | grep -B1 "$device" | awk -F': ' '/Hardware Port:/{print $NF}')
		portNames+=("$portName")
	fi
done

echo "<result>$(printf '%s\n' "${portNames[@]}")</result>"
