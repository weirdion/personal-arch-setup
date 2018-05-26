###Arch Install Helper Notes

# Create bootable USB

sdX needs to be replaced by the correct USB letter
```bash
# dd if=/path/to/archlinux.iso of=/dev/sdX bs=8M status=progress && sync
```

# Reboot system to boot from USB. Once in Arch shell, set up ntp and wifi.

```bash
# timedatectl set-ntp true
# wifi-menu
# ping -c 3 www.google.com
```

# Partition the disk with gdisk or fdisk

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
