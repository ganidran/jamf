# Jamf Collection

## Overview

This repository contains a collection of scripts designed for use with Jamf. These scripts are tailored to automate various tasks related to device management, configuration, and maintenance within an MDM environment. 

## Details

### Apps
*Some installer scripts for apps that live outside the "Mac Apps" solution in Jamf for a little more control.*
<details>
<summary markdown="span"><strong>1Password Installer</strong></summary>
<br>
  
[1passwordInstaller](https://github.com/ganidran/jamf/blob/main/Apps/1passwordInstaller.sh) | 
Checks for 1Password 7, uninstalls it if found and installs the latest 1Password app. It's been found that 1Pass 7 could be vulnerable and it's suggested to remove it first.
<br><br>
</details>

<details>
<summary markdown="span"><strong>Chrome Installer</strong></summary>
<br>

[chromeInstaller](https://github.com/ganidran/jamf/blob/main/Apps/chromeInstaller.sh) | 
Quick and easy installer for Google Chrome. The URL already acknowledges the terms of agreement. [See this for more info](https://support.google.com/chrome/a/answer/9915669?hl=en).
<br><br>
</details>

<details>
<summary markdown="span"><strong>Notion Installer</strong></summary>
<br>

[notionInstaller](https://github.com/ganidran/jamf/blob/main/Apps/notionInstaller.sh) | 
Installs Notion in the background based on chip architecture. It also adds ownership/permissions to the app.
<br><br>

</details>

<details>
<summary markdown="span"><strong>Spotify Installer</strong></summary>
<br>

[spotifyInstaller](https://github.com/ganidran/jamf/blob/main/Apps/spotifyInstaller.sh) | 
Installs Spotify in the background based on chip architecture. It also adds ownership/permissions to the app.
<br><br>

</details>

<details>
<summary markdown="span"><strong>swiftDialog Helper</strong></summary>
<br>

[swiftdialogInstallHelper](https://github.com/ganidran/jamf/blob/main/Apps/swiftdialogInstallHelper.sh) | 
A script that I add to the installer policy along with the swiftDialog package to make it easy for the app icon to update as well as loading font daemons to avoid font errors in the output log. 
<br><br>

</details>

<details>
<summary markdown="span"><strong>Xcode Installer</strong></summary>
<br>

[xcodeInstaller](https://github.com/ganidran/jamf/blob/main/Apps/xcodeInstaller.sh) | 
Modified script from James Smith's guide [found here](https://smithjw.me/posts/2022-05-20-installing-xcode-xip/). 
</details>
<br>

### Enrollment
*A few scripts deployed at enrollment. They're each part of their own policy. Governed by the "Master Enrollment" script, which then runs the rest of the scripts. It also assumes existing policies are in place for apps based on custom policy events.*
<details>
<summary markdown="span"><strong>Default Apps</strong></summary>
<br>

[defaultApps](https://github.com/ganidran/jamf/blob/main/Enrollment/defaultApps.sh) | 
Sets default apps for a browser and an email client via a corresponding agent string. Example: `com.google.Chrome` if you want to make Chrome the default for both. May require a restart and that can be set in this script or elsewhere (it's in the "Master Enrollment" script here). 
<br><br>
</details>

<details>
<summary markdown="span"><strong>Master Enrollments</strong></summary>
<br>

[masterEnroll](https://github.com/ganidran/jamf/blob/main/Enrollment/masterEnroll.sh) | 
Master script used to enroll a machine and properly install all that it may need. It places a full screen window so that a user can't use their machine as items install. It's an alternative to Jamf's solution and others out there to allow for more customization. Once installation is complete, it restarts the computer at the end. It leverages [swiftDialog](https://github.com/swiftDialog/swiftDialog/wiki) for the prompt along with a custom company image (if available).
<br><br>
</details>

<details>
<summary markdown="span"><strong>Set Desktop Image</strong></summary>
<br>

[setDesktopImage](https://github.com/ganidran/jamf/blob/main/Enrollment/setDesktopImage.sh) | 
Sets a desktop image during enrollment. This is contingent on a policy that both installs [desktoppr](https://github.com/scriptingosx/desktoppr) and a custom wallpaper image into /Library/Desktop Pictures. That'll allow for users to both modify it and/or change back to it via System Settings if they want to. Separate from the Jamf solution. 
<br><br>
</details>

<details>
<summary markdown="span"><strong>Set Dock</strong></summary>
<br>

[setDock](https://github.com/ganidran/jamf/blob/main/Enrollment/setDock.sh) | 
Sets a collection of apps, shortcuts and/or folders to the dock based on macOS version. Custom dock is created by Techion's [Dock Master](https://techion.com.au/blog/2015/4/28/dock-master).
<br><br>
</details>

<details>
<summary markdown="span"><strong>Set User Icon</strong></summary>
<br>

[setUserIcon](https://github.com/ganidran/jamf/blob/main/Enrollment/setUserIcon.sh) | 
Sets a predefined user icon during enrollment. This assumes you've packaged and deployed user images to the path in this script earlier in the enrollment process.
</details>
<br>

### Extension Attributes
*Some probable useful extension attributes to create policies, checks, etc around them.*
<details>
<summary markdown="span"><strong>Active Network</strong></summary>
<br>

[activeNetwork](https://github.com/ganidran/jamf/blob/main/Extension-Attributes/activeNetwork.sh) | 
Displays what the active network of a computer is. Ie: ethernet, Wi-Fi, etc..
<br><br>

</details>

<details>
<summary markdown="span"><strong>Check Code42 Status</strong></summary>
<br>

[checkCode42](https://github.com/ganidran/jamf/blob/main/Extension-Attributes/checkCode42.sh) | 
If you have Code42 installed, this is a great way to check its status. 
<br><br>

</details>

<details>
<summary markdown="span"><strong>Check If User is an Admin</strong></summary>
<br>

[checkIfUserIsAdmin](https://github.com/ganidran/jamf/blob/main/Extension-Attributes/checkIfUserIsAdmin.sh) | 
Outputs a binary response after checking if the user is an admin. 
<br><br>

</details>

<details>
<summary markdown="span"><strong>Code42 GUID</strong></summary>
<br>

[code42GUID](https://github.com/ganidran/jamf/blob/main/Extension-Attributes/code42Guid.sh) | 
Grabs the GUID from the machine and adds it to Jamf. This helps in auditing and cross-referencing both since Incydr doesn't 'display serial numbers. 
<br><br>

</details>

<details>
<summary markdown="span"><strong>Homebrew Status</strong></summary>
<br>

[homebrew](https://github.com/ganidran/jamf/blob/main/Extension-Attributes/homebrew.sh) | 
Easy way to check if Homebrew is installed on a Mac. 
<br><br>

</details>

<details>
<summary markdown="span"><strong>Is Signed Into iCloud</strong></summary>
<br>

[isSignedIntoIcloud](https://github.com/ganidran/jamf/blob/main/Extension-Attributes/isSignedIntoIcloud.sh) | 
Checks to see if the user is signed into iCloud and if so, spits out the Apple ID(s) used. Can be used to scope policies and/or config profiles to these users.
<br><br>

</details>

<details>
<summary markdown="span"><strong>Is Printer Installed</strong></summary>
<br>

[printerInstalled](https://github.com/ganidran/jamf/blob/main/Extension-Attributes/printerInstalled.sh) | 
Based on printer IP, checks to see if that specific printer is installed. Found this easier for certain scopes. 
<br><br>

</details>

<details>
<summary markdown="span"><strong>Uptime Check</strong></summary>
<br>

[uptime](https://github.com/ganidran/jamf/blob/main/Extension-Attributes/uptime.sh) | 
Displays a computer's uptime. 

</details>
<br>

### Misc
*Random set of scripts that don't have their own category.*

<details>
<summary markdown="span"><strong>macOS Version</strong></summary>
<br>

[osVersionCheck](https://github.com/ganidran/jamf/blob/main/Misc/osVersionCheck.sh) | 
Quick if/then statement that displays what the major macOS version is and continues on depending on which. Can be modified as needed.
<br><br>

</details>

<details>
<summary markdown="span"><strong>Reset Network</strong></summary>
<br>

[resetNetwork](https://github.com/ganidran/jamf/blob/main/Misc/resetNetwork.sh) | 
A way to nuke/reset a computers Network on a Mac. The same ideas as "Reset Network Settings" on iOS.
<br><br>

</details>
<br>

### Prompts
*Prompts that appear for the user. Some contain action items, others are simply prompts. All prompts here leverage [swiftDialog](https://github.com/swiftDialog/swiftDialog/wiki) along with a custom company image (if available).*

<details>
<summary markdown="span"><strong>Chrome Updater</strong></summary>
<br>

[chromeUpdate](https://github.com/ganidran/jamf/blob/main/Prompts/chromeUpdate.sh) | 
Updates Chrome in the background if it's not managed by Google Workspace Admin. Parameter 4 specifies the release date of the latest update. Parameter 5 specifies the Chrome version.
<br><br>

</details>

<details>
<summary markdown="span"><strong>Reboot with Deferrals</strong></summary>
<br>

[deferredRestart](https://github.com/ganidran/jamf/blob/main/Prompts/deferredRestart.sh) | 
A prompt that asks users to reboot the computer alongside a set number of deferrals. There's a prompt for when there are deferrals left and one for when there are no more. 
<br><br>

</details>

<details>
<summary markdown="span"><strong>FileVault Key Reissue</strong></summary>
<br>

[filevaultRekey](https://github.com/ganidran/jamf/blob/main/Prompts/filevaultRekey.sh) | 
Modified script from Elliot Jordan's guide [found here](https://github.com/homebysix/jss-filevault-reissue) to utilize swiftDialog and run a recon at the end.
<br><br>

</details>

<details>
<summary markdown="span"><strong>Sign Out of iCloud</strong></summary>
<br>

[icloudSignOut](https://github.com/ganidran/jamf/blob/main/Prompts/icloudSignOut.sh) | 
In the rare times someone is able to sign into iCloud when a config profile restricts it, this prompts the user to sign out. Works in tandem with the extension attribute above to create a smart group scoped to users that are signed in.
<br><br>

</details>

<details>
<summary markdown="span"><strong>macOS Update Reminder</strong></summary>
<br>

[macosUpdateReminder](https://github.com/ganidran/jamf/blob/main/Prompts/macosUpdateReminder.sh) | 
A prompt that urges users to update. Parameter 4 is the date that the OS version was released - this is done so that the referral plist is unique to each OS version in case we need to audit (otherwise it overrides the plist if the filename is the same). This is used in tandem with policies using Graham Pugh's [erase-install](https://github.com/grahampugh).  
<br><br>

</details>

<details>
<summary markdown="span"><strong>Zoom Update</strong></summary>
<br>

[updateZoom](https://github.com/ganidran/jamf/blob/main/Prompts/updateZoom.sh) | 
Prompts user to update Zoom if it's not done automatically.  

</details>
<br>

### Security
*A few scripts that I figured would be considered part of security.*

<details>
<summary markdown="span"><strong>Demote User from Admin</strong></summary>
<br>

[demoteUserFromAdmin](https://github.com/ganidran/jamf/blob/main/Security/demoteUserFromAdmin.sh) | 
Script that demotes a user as Admin. Used when admins are given perms temporarily. I saw Jamf recently come out with this feature (as of 04.2024) but again, I enjoy having a bit more control. 
<br><br>

</details>

<details>
<summary markdown="span"><strong>Jamf Compliance Check</strong></summary>
<br>

[jamfComplianceCheck](https://github.com/ganidran/jamf/blob/main/Security/jamfComplianceCheck.sh) | 
Quick script that checks compliance of an asset with Jamf Pro. 
<br><br>

</details>

<details>
<summary markdown="span"><strong>Promote User to Admin</strong></summary>
<br>

[promoteUserToAdmin](https://github.com/ganidran/jamf/blob/main/Security/promoteUserToAdmin.sh) | 
Similar to demoteUserFromAdmin, this promotes a user to admin. Deployed via Self Service when working with a user remotely. 

</details>

## License

This project is licensed under the [MIT License](https://www.mit.edu/~amini/LICENSE.md).
