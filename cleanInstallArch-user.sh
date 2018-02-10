#!/bin/bash

# Script to run as a non-root user.
# This script creates soft-links, restore backup config files 
# and run pacaur for remaining applications.
#
# Created By: Ankit Sadana
# Created On: 02/13/2018
# Last Edited On: 02/13/2018

declare -r scriptUser="ankit"
declare -r storeMountDir="/run/media/$scriptUser/store"
declare -r homeDir="/home/$scriptUser"

createSoftLinks() {	
	echo
	read -r -p "Do you want to delete \"Documents\", \"Pictures\" and \"Downloads\"  before creating soft links? [y/n]: " response
	response=${response,,}    # to lower
	if [[ "$response" =~ ^(yes|y)$ ]]; then
		if [[ -d "$homeDir/Documents" ]]; then
			rm -vrf $homeDir/Documents
		fi
		if [[ -d "$homeDir/Pictures" ]]; then
			rm -vrf $homeDir/Pictures
		fi
		if [[ -d "$homeDir/Downloads" ]]; then
			rm -vrf $homeDir/Downloads
		fi
	else
	    exit;
	fi

	echo "Starting to generate soft links"
	ln -s "$storeMountDir" "$homeDir/store" && \
	ln -s "$storeMountDir/Documents" "$homeDir/Documents" && \
	ln -s "$storeMountDir/Downloads" "$homeDir/Downloads" && \
	ln -s "$storeMountDir/Episodes" "$homeDir/Episodes" && \
	ln -s "$storeMountDir/GoogleDrive" "$homeDir/GoogleDrive" && \
	ln -s "$storeMountDir/Movies" "$homeDir/Movies" && \
	ln -s "$storeMountDir/Pictures" "$homeDir/Pictures" && \
	ln -s "$storeMountDir/torrents" "$homeDir/torrents" && \
	ln -s "$storeMountDir/wallpapers" "$homeDir/wallpapers" && \
	ln -s "$storeMountDir/workspace" "$homeDir/workspace" && \
	ln -s "$storeMountDir/android-sdk" "$homeDir/android-sdk"

	echo
	echo "Soft links created"
	ls -al --color=auto $homeDir
}

copyConfigFilesFromBackup() {
	echo
	read -r -p "Do you want to copy/replace bashrc and stuff? [y/n]: " response2
	response2=${response2,,}
	echo
	if [[ "$response2" =~ ^(yes|y)$ ]]; then
		# rm -v $homeDir/.bashrc
		rm -v $homeDir/.face
		rm -v $homeDir/.face.icon
		rm -v $homeDir/.gitconfig
		rm -rfv $homeDir/.m2
		rm -rfv $homeDir/.ssh
		# cp -v $storeMountDir/backup/.bashrc $homeDir/
		cp -v $storeMountDir/backup/.face $homeDir/ && \
		cp -v $storeMountDir/backup/.face.icon $homeDir/ && \
		cp -v $storeMountDir/backup/.gitconfig $homeDir/ && \
		cp -rv $storeMountDir/backup/.config/kfoldersync $homeDir/.config/ && \
		cp -rv $storeMountDir/backup/.m2 $homeDir/.m2 && \
		cp -rv $storeMountDir/backup/.ssh $homeDir/.ssh
	fi
	echo
}

installApplicationsWithPacaur() {
	pacaur -S jdk8 vim ntfs-3g	
	pacaur -S tilix-bin plex-media-server remmina remmina-plugin-rdesktop insync firefox-beta-bin \
	google-chrome-beta git evolution qbittorrent openvpn networkmanager-openvpn openssh sublime-text-dev freerdp \
	intellij-idea-community-edition firefox-beta-bin powertop vlc private-internet-access-vpn python pip android-studio-beta p7zip
}

# Check if script is running as root
if [ "$EUID" -eq 0 ]
  then echo "Please run this script as a non-root user"
  exit
else
	createSoftLinks
	copyConfigFilesFromBackup
	installApplicationsWithPacaur
fi

