#!/bin/bash

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

echo "Welcome to the Arch Linux installation script."

# Prompt for the disk to use for installation
echo "Please select the disk to use for installation:"
lsblk
read -p "Enter the disk (e.g., /dev/sda): " install_disk

# Partition the disk
echo "Partitioning the disk..."
sgdisk --zap-all "$install_disk"
sgdisk -n 1:2048:4095 -c 1:"BIOS Boot Partition" -t 1:ef02 "$install_disk"
sgdisk -n 2:0:+512M -c 2:"EFI System Partition" -t 2:ef00 "$install_disk"
sgdisk -n 3:0:0 -c 3:"Linux Filesystem" -t 3:8300 "$install_disk"

# Format the partitions
echo "Formatting partitions..."
mkfs.ext2 "${install_disk}2"  # EFI System Partition
mkfs.btrfs "${install_disk}3" # Linux Filesystem

# Set up Btrfs subvolumes
echo "Creating Btrfs subvolumes..."
mount "${install_disk}3" /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
umount /mnt

# Mount the subvolumes
echo "Mounting partitions..."
mount -o noatime,compress=zstd,space_cache,subvol=@ "${install_disk}3" /mnt
mkdir /mnt/home
mount -o noatime,compress=zstd,space_cache,subvol=@home "${install_disk}3" /mnt/home
mkdir /mnt/boot
mount "${install_disk}2" /mnt/boot

# Install essential packages and GNOME desktop environment (same as previous examples)
# Generate fstab (same as previous examples)
# Install yay (AUR helper, same as previous examples)
# Install Google Chrome using yay (same as previous examples)
# Install Surface Linux kernel from GitHub (same as previous examples)
# Prompt for the new user (same as previous examples)

# Create the new user (same as previous examples)

# Give sudo access to the new user (same as previous examples)

# Install and configure the GRUB bootloader (assuming UEFI system)
echo "Installing GRUB bootloader..."
pacman -S --noconfirm grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch_grub
grub-mkconfig -o /boot/grub/grub.cfg

# Enable NetworkManager
systemctl enable NetworkManager

# Rest of the installation process...
# (the rest of the script from the previous examples)
