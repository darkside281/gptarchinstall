#!/bin/bash

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

echo "Welcome to the Arch Linux installation script."

# Prompt for the keyboard layout, locale, and time zone (same as previous examples)

# Install essential packages and GNOME desktop environment (same as previous examples)

# Generate fstab (same as previous examples)

# Install yay (AUR helper, same as previous examples)

# Install Google Chrome using yay (same as previous examples)

# Install Surface Linux kernel from GitHub (same as previous examples)

# Prompt for the new user
read -p "Enter your desired username: " username

# Create the new user
useradd -m -G wheel "$username"
echo "Set a password for the new user:"
passwd "$username"

# Give sudo access to the new user
read -p "Do you want to grant sudo access to $username? (y/N): " grant_sudo
if [[ "$grant_sudo" =~ ^[Yy]$ ]]; then
  echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
fi

# Install and configure the GRUB bootloader (assuming UEFI system)
echo "Installing GRUB bootloader..."
pacman -S --noconfirm grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch_grub
grub-mkconfig -o /boot/grub/grub.cfg

# Enable NetworkManager
systemctl enable NetworkManager

# Rest of the installation process...
# (the rest of the script from the previous examples)
