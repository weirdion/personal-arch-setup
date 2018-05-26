# Arch Install Helper Notes

---

## Create bootable USB

sdX needs to be replaced by the correct USB letter
```bash
# dd if=/path/to/archlinux.iso of=/dev/sdX bs=8M status=progress && sync
```

## Reboot system to boot from USB. Once in Arch shell, set up ntp and wifi.

```bash
# timedatectl set-ntp true
# wifi-menu
# ping -c 3 www.google.com
```

## Partition the disk with gdisk or fdisk

Depending on how you want your set up to be, set up partitions.
For my use case, I want
```
/dev/sda
    /dev/sda1 1024MB  /boot       -> For Systemd-boot
    /dev/sda2 120GB   crypt/LLVM  -> For the root and swap (Size dependent on your needs)
        archgrp-swap  8GB   swap  -> Swap partition (optional if you want to do a Swapfile inside root instead)
        archgrp-root  112GB xfs   -> Root partition
    /dev/sda3 810GB   crypt       -> Can be LLVM if needed
        store         810GB xfs   -> For data/backup partition that will persist across distros
```

Now let's set this stuff up.
```bash
# gdisk /dev/sda
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
Last sector (2101248-1953525134, default = 1953525134) or {+-}size{KMGTP}: +120G
Current type is 'Linux filesystem'
Hex code or GUID (L to show codes, Enter = 8300): 
Changed type of partition to 'Linux filesystem'

Command (? for help): n
Partition number (3-128, default 3): 
First sector (34-1953525134, default = 253759488) or {+-}size{KMGTP}: 
Last sector (253759488-1953525134, default = 1953525134) or {+-}size{KMGTP}: 
Current type is 'Linux filesystem'
Hex code or GUID (L to show codes, Enter = 8300): 
Changed type of partition to 'Linux filesystem'

Command (? for help): p
Disk /dev/sda: 1953525168 sectors, 931.5 GiB
Model: ST1000LM024 HN-M
Sector size (logical/physical): 512/4096 bytes
Disk identifier (GUID): C379CC43-EE63-4CD5-A0FA-E37EDDDA2C8D
Partition table holds up to 128 entries
Main partition table begins at sector 2 and ends at sector 33
First usable sector is 34, last usable sector is 1953525134
Partitions will be aligned on 2048-sector boundaries
Total free space is 2014 sectors (1007.0 KiB)

Number  Start (sector)    End (sector)  Size       Code  Name
   1            2048         2101247   1.0 GiB     EF00  EFI System
   2         2101248       253759487   120.0 GiB   8300  Linux filesystem
   3       253759488      1953525134   810.5 GiB   8300  Linux filesystem

Command (? for help): w
```

Now that we have all the partitions set, time to format and set up encryption and llvm.

## Format, Encrypt and LLVM

```bash
mkfs.vfat -F32 /dev/sda1 # Format sda1 with Fat32

cryptsetup -v luksFormat /dev/sda2 # Encrypt sda2 with Luks
cryptsetup luksOpen /dev/sda2 arch # Open the newly encrypted drive and name it arch

pvcreate /dev/mapper/arch # Create a Physical Volume
vgcreate archgrp /dev/mapper/arch # Create a Volume Group named archgrp
lvcreate -L 8G archgrp -n swap # Create a Logical Volume for swap with size 8GB
lvcreate -l +100%FREE archgrp -n root # Create a Logical Volume for root with remaining size

mkswap -f /dev/mapper/archgrp-swap -L swap # Make swap, label it swap
mkfs.xfs -f /dev/mapper/archgrp-root -L archOS # Format root as XFS, label it archOS

mount /dev/mapper/archgrp-root /mnt # Mount root at /mnt
swapon /dev/mapper/archgrp-swap # Mount swap

mkdir /mnt/boot # Create a dir inside root (/mnt)
mount /dev/sda1 /mnt/boot # Mount sda1 to /mnt/boot
```
