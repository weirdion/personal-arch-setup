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
