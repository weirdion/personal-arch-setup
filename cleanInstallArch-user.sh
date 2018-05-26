#!/bin/bash

# Script to run as a non-root user.
# This script creates soft-links, restore backup config files 
# and run pacaur for remaining applications.
#
# Created By: Ankit Sadana
# Created On: 02/13/2018
# Last Edited On: 05/25/2018

declare -r scriptUser="asadana"
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
	cp -rv "$storeMountDir/.AndroidStudio3.0" "$homeDir/.AndroidStudio3.0"
	cp -rv "$storeMountDir/.IdeaIC2018.1" "$homeDir/.IdeaIC2018.1"

	echo
	echo "Soft links created"
	ls -ahl --color=auto $homeDir
}

copyConfigFilesFromBackup() {
	echo
	read -r -p "Do you want to delete existing bashrc and stuff and restore from backup? [y/n]: " response2
	response2=${response2,,}
	echo
	if [[ "$response2" =~ ^(yes|y)$ ]]; then
		rm -v $homeDir/.bashrc
		rm -v $homeDir/.face
		rm -v $homeDir/.face.icon
		rm -v $homeDir/.gitconfig
		rm -rfv $homeDir/.m2
		rm -rfv $homeDir/.ssh
		cp -v $storeMountDir/backup/.bashrc $homeDir/
		cp -v $storeMountDir/backup/.face $homeDir/ && \
		cp -v $storeMountDir/backup/.gitconfig $homeDir/ && \
		cp -rv $storeMountDir/backup/.config/kfoldersync $homeDir/.config/ && \
		cp -rv $storeMountDir/backup/.m2 $homeDir/.m2 && \
		cp -rv $storeMountDir/backup/.ssh $homeDir/.ssh
		ln -s $homeDir/.face $homeDir/.face.icon
	fi
	echo
}

installApplicationsWithPacaur() {
	pacaur -S --noconfirm jdk8-openjdk vim ntfs-3g
	pacaur -S --noconfirm tilix-bin plex-media-server remmina remmina-plugin-rdesktop insync xkeychain maven \
	google-chrome-beta git evolution qbittorrent openvpn networkmanager-openvpn openssh sublime-text-dev freerdp gradle \
	powertop vlc python p7zip
	pacaur -S --noconfirm telegram-desktop-bin slack-desktop discord
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

