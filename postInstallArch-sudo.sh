#!/bin/bash

# Script to run as a root user.
# This script mounts the backup partition, installs graphics for bumblebee,
# sets up groups for user and appends fstab for the backup partition.
#
# Created By: Ankit Sadana
# Created On: 02/13/2018
# Last Edited On: 05/26/2018

declare -r scriptUser="asadana"
declare -r storeMountDir="/run/media/$scriptUser/store"
declare -r homeDir="/home/$scriptUser"
declare -r storeBlock=/dev/mapper/store

echo "$USER used when running this script"

mountStore() {
	# Check if dir exxists or create one
	if [ ! -d "$storeMountDir" ]; then
		echo "Creating directory $storeMountDir"
		mkdir -p $storeMountDir
	else
		echo "Directory already exists"
	fi

	# Mount block onto dir
	if [ -d "$storeMountDir" ]; then
		echo "Attempting to mount $storeBlock onto $storeMountDir"
		mount $storeBlock $storeMountDir
	else 
		echo "Directory $storeMountDir not found, please check manually and try again.."
		exit
	fi

	# Check if the block was mounted successfully
	if mount | grep "$storeBlock" > /dev/null ; then
		echo "$storeBlock was successfully mounted"
	else
		echo "Failed to mount $storeBlock"
		exit
	fi
}

handlePacmanApplications() {
	pacman -Rc xf86-video-nouveau
	pacman -R firefox
	#pacman -S bumblebee mesa xf86-video-intel nvidia lib32-nvidia-utils lib32-virtualgl nvidia-settings bbswitch 
	#systemctl enable bumblebeed.service
}

handleGroups() {
	groupadd sdkusers
	groupadd plex
	gpasswd -a $scriptUser lp
	gpasswd -a $scriptUser sdkusers
	gpasswd -a $scriptUser adm
	gpasswd -a $scriptUser scanner
	gpasswd -a $scriptUser ftp
	gpasswd -a $scriptUser rfkill
	gpasswd -a $scriptUser sys
	#gpasswd -a $scriptUser bumblebee
	gpasswd -a $scriptUser video
	gpasswd -a $scriptUser plex
}

# Pulls the backed up lines from fstab-store
appendFstab() {
	echo
	read -r -p "Do you want to add to fstab? [y/n]: " response3
	response3=${response3,,}
	if [[ "$response3" =~ ^(yes|y)$ ]]; then
		echo "Making a backup for fstab"
		cp -v /etc/fstab /etc/fstab.backup
		while read line; do
			echo $line >> /etc/fstab
		done < $storeMountDir/backup/fstab-store
		echo "fstab appending complete"
		echo
		cat /etc/fstab
	fi
}

# Check if script is running as root
if [ "$EUID" -ne 0 ]
  then echo "Please run this script as root"
  exit
else
	handlePacmanApplications
	mountStore
	handleGroups
	appendFstab
fi

# Not needed anymore unless using Grub2
# sudo cp -rv $storeMountDir/backup/themes/ /boot/grub/themes/
