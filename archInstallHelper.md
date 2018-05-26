# Arch Install Helper Notes

---

## Create bootable USB

sdX needs to be replaced by the correct USB letter
```bash
sudo dd if=/path/to/archlinux.iso of=/dev/sdX bs=8M status=progress && sync
```

## Reboot system to boot from USB. Once in Arch shell, set up ntp and wifi.

```bash
timedatectl set-ntp true
wifi-menu
ping -c 3 www.google.com
```

## Partition the disk with gdisk or fdisk

Depending on how you want your set up to be, set up partitions.
For my use case, I want
```
/dev/sda
    /dev/sda1 1024MB  /boot       -> For Systemd-boot
    /dev/sda2 8GB     swap        -> Swap partition (optional, if you want to do a Swapfile in root instead)
    /dev/sda3 120GB   xfs         -> Root partition
    /dev/sda4 802GB   xfs         -> For data/backup partition that will persist across distros
```

Now let's set this stuff up.
```bash
gdisk /dev/sda
```

```
GPT fdisk (gdisk) version 1.0.1

Partition table scan:
  MBR: protective
  BSD: not present
  APM: not present
  GPT: present

Found valid GPT with protective MBR; using GPT.

Command (? for help): ?
b	back up GPT data to a file
c	change a partition's name
d	delete a partition
i	show detailed information on a partition
l	list known partition types
n	add a new partition
o	create a new empty GUID partition table (GPT)
p	print the partition table
q	quit without saving changes
r	recovery and transformation options (experts only)
s	sort partitions
t	change a partition's type code
v	verify disk
w	write table to disk and exit
x	extra functionality (experts only)
?	print this menu

Command (? for help): o
This option deletes all partitions and creates a new protective MBR.
Proceed? (Y/N): Y

Command (? for help): n
Partition number (1-128, default 1): 
First sector (34-1953525134, default = 2048) or {+-}size{KMGTP}:      
Last sector (2048-1953525134, default = 1953525134) or {+-}size{KMGTP}: +1025M
Current type is 'Linux filesystem'
Hex code or GUID (L to show codes, Enter = 8300): EF00
Changed type of partition to 'EFI System'

Command (? for help): n
Partition number (2-128, default 2): 
First sector (34-1953525134, default = 2101248) or {+-}size{KMGTP}: 
Last sector (2101248-1953525134, default = 1953525134) or {+-}size{KMGTP}: +8G
Current type is 'Linux filesystem'       
Hex code or GUID (L to show codes, Enter = 8300): 8200
Changed type of partition to 'Linux swap'

Command (? for help): n
Partition number (3-128, default 3): 
First sector (34-1953525134, default = 18878464) or {+-}size{KMGTP}: 
Last sector (18878464-1953525134, default = 1953525134) or {+-}size{KMGTP}: +120G
Current type is 'Linux filesystem'
Hex code or GUID (L to show codes, Enter = 8300): 
Changed type of partition to 'Linux filesystem'

Command (? for help): n
Partition number (4-128, default 4): 
First sector (34-1953525134, default = 270536704) or {+-}size{KMGTP}: 
Last sector (270536704-1953525134, default = 1953525134) or {+-}size{KMGTP}: 
Current type is 'Linux filesystem'
Hex code or GUID (L to show codes, Enter = 8300): 
Changed type of partition to 'Linux filesystem'

Command (? for help): p
Disk /dev/sda: 1953525168 sectors, 931.5 GiB
Model: ST1000LM024 HN-M
Sector size (logical/physical): 512/4096 bytes
Disk identifier (GUID): F725BC15-CDCF-4862-9CA9-81AFB7746884
Partition table holds up to 128 entries
Main partition table begins at sector 2 and ends at sector 33
First usable sector is 34, last usable sector is 1953525134
Partitions will be aligned on 2048-sector boundaries
Total free space is 4061 sectors (2.0 MiB)

Number  Start (sector)    End (sector)  Size       Code  Name
   1            2048         2099200   1024.0 MiB  EF00  EFI System
   2         2101248        18878463   8.0 GiB     8200  Linux swap
   3        18878464       270536703   120.0 GiB   8300  Linux filesystem
   4       270536704      1953525134   802.5 GiB   8300  Linux filesystem

Command (? for help): w
```

Now that we have all the partitions set, time to format and mount everything.

## Format and Mount

```bash
pacman -S xfsprogs

mkfs.vfat -F32 /dev/sda1 # Format sda1 with Fat32

mkswap -f /dev/sda2 -L swap # Make swap, label it swap
mkfs.xfs -f /dev/sda3 -L archOS # Format root as XFS, label it archOS
mkfs.xfs -f /dev/sda4 -L backup # Format the backup partition to XFS and label it backup

swapon /dev/sda2 # Mount swap
mount /dev/sda3 /mnt # Mount root at /mnt

mkdir /mnt/boot # Create a dir inside root (/mnt)
mount /dev/sda1 /mnt/boot # Mount sda1 to /mnt/boot
```

## Installing Arch base

```bash
# Open mirrorlist and choose nearby mirror and copy (Alt+6) and paste (Ctr+U) at top.
nano /etc/pacman.d/mirrorlist 
pacstrap /mnt base base-devel # Install the arch base and base-devel
genfstab -pU /mnt > /mnt/etc/fstab # Generate fstab
```

*NOTE:* For all non-boot partitions SSD partitions, edit `/mnt/etc/fstab` and change relatime to noatime.


## chroot into the system and set it up

```bash
arch-chroot /mnt

# Set your timezone as Symbolic link to /etc/localtime
ln -s /usr/share/zoneinfo/America/Indianapolis /etc/localtime
hwclock --systohc

echo archOS > /etc/hostname # Set your hostname to archOS (or something else)

# Set your root password
passwd

# Create a user
# useradd -m -G additional_groups -s login_shell username
useradd -m -G wheel -s /bin/bash asadana # wheel group is used for admin, skip group for regular user.

# Set password for your new user
passwd asadana

# Make sure sudo is installed
pacman -S sudo

# Let's enable wheel as sudo users
EDITOR=nano visudo
```

Uncomment this line, then save and exit
```bash
%wheel ALL=(ALL) ALL
```

## Set up locales

```bash
#Uncomment en_US.UTF-8 UTF-8 in /etc/locale.gen
nano /etc/locale.gen

# Echo UTF-8 to /etc/locale.conf
echo LANG=en_US.UTF-8 > /etc/locale.conf

locale-gen
```

## Set up multilib and install a few basic things

```bash
nano /etc/pacman.conf # Edit pacman.conf
# Uncomment the following in /etc/pacman.conf

# Misc options
Color
.
.
.
[multilib]
Include = /etc/pacman.d/mirrorlist
```

Save, exit and sync
```bash
pacamn -Sy
```

Let's a couple things,

```bash
# Make sure your system has everything we are using
pacman -S xfsprogs

# Some general tools, net-tools is optional but nice to have

pacman -S bash-completion dialog wpa_supplicant net-tools

# Xorg and drivers
pacman -S xorg-server xorg-server-utils xf86-video-intel
```


## Set up systemd-boot

```bash
# install systemd-boot to /boot
bootctl --path=/boot install
```

Edit /etc/mkinitcpio.conf, add xfs to modules.

```
MODULES="xfs"
.
.
.
HOOKS="base udev autodetect modconf block keymap resume filesystems keyboard fsck"
```

## Configure bootloader entries for systemd-boot

Edit /boot/loader/loader.conf
(This contains which entry is loaded by default, and timeout in seconds)

```bash
timeout 3
default arch
editor 0
```

Let's first check your /dev/sda2 and /dev/sda3 UUID for the next step
```bash
blkid /dev/sda2
blkid /dev/sda3
```

Create /boot/loader/entries/arch.conf
(This contains arch linux entry to boot archOS we just installed)

```bash
title	Arch Linux
linux	/vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options root=UUID=<UUID-sda3-PARTITION> resume=UUID=<UUID-sda2-PARTITION> rw
```

## Finish installation and reboot the system

```bash
mkinitcpio -p linux
exit
umount -R /mnt
reboot
```

## Upon reboot

Arch should boot into a console.

```bash
# Connect WiFi
wifi-menu

# Ping google
ping -c 3 google.com
```

Let's set up "Yay" for secure AUR access

```bash
# Install git and go for Yay
sudo pacman -S --noconfirm wget

mkdir temp # temporary dir for installing yay
cd temp
wget https://aur.archlinux.org/cgit/aur.git/snapshot/yay.tar.gz
tar -xvf yay.tar.gz
cd yay

# Review the PKGBUILD to make sure you know what the script is doing
cat PKGBUILD

# Install
makepkg -sri
```

Finally, unless you want a headless system, lets install a Desktop Environment.

```bash
sudo pacman -S plasma # "plasma is a group that will install general components of kde"
# For other groups and desktop environments see https://www.archlinux.org/groups/x86_64/

# Let's enable NetworkManager and SDDM for KDE.
sudo systemctl enable NetworkManager.service
sudo systemctl enable sddm.service

# Let's do a reboot just for a clean start
sudo shutdown -r now
#
```

Enjoy!
