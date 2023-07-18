#!/bin/bash

# Check if the script is running with root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root or with sudo."
  exit 1
fi

# Check if the kernel paths are provided as arguments
if [ $# -ne 2 ]; then
  echo "Usage: $0 /path/to/vmlinuz /path/to/initramfs"
  exit 1
fi

# Check if the specified kernel files exist
if [ ! -f "$1" ] || [ ! -f "$2" ]; then
  echo "Error: One or both kernel files not found."
  exit 1
fi

# Get the root partition UUID
root_uuid=$(blkid -o value -s UUID /dev/your_root_partition)  # Replace /dev/your_root_partition with your actual root partition device

# Create the systemd-boot entry file
cat << EOF > /boot/loader/entries/surface-linux.conf
title Surface Linux
linux $1
initrd $2
options root=UUID=$root_uuid rw quiet splash
EOF

# Update systemd-boot
bootctl update

echo "Systemd-boot entry for the custom kernel has been created successfully."
