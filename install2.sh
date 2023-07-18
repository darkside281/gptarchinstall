#!/bin/bash

# Function to display a message with a separator
function print_message() {
    echo "=========================================="
    echo "$1"
    echo "=========================================="
}

# Check if the script is being run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root."
   exit 1
fi

# Check for internet connectivity
print_message "Checking internet connectivity..."
ping -c 3 google.com > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Internet connection not found. Please connect to the internet and run the script again."
    exit 1
fi

# List available disk drives
print_message "Available disk drives:"
lsblk
echo

# Prompt for disk selection
read -p "Enter the disk to use for installation (e.g., /dev/sda): " disk

# Partition and format the disk
print_message "Partitioning and formatting the disk $disk..."
sgdisk --clear \
       --new=1:0:0 \
       --typecode=1:ef00 \
       $disk
mkfs.btrfs -L arch /dev/sdX1
mount /dev/sdX1 /mnt

# Create a swap file in the root partition
print_message "Creating a swap file..."
truncate -s 0 /mnt/swapfile
chattr +C /mnt/swapfile
btrfs property set /mnt/swapfile compression none
dd if=/dev/zero of=/mnt/swapfile bs=1M count=4096
chmod 600 /mnt/swapfile
mkswap /mnt/swapfile
swapon /mnt/swapfile

# Install base packages
print_message "Installing base packages..."
pacstrap /mnt base base-devel linux linux-firmware

# Generate fstab
print_message "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot into the new system
print_message "Chrooting into the new system..."
arch-chroot /mnt

# Set the time zone
print_message "Setting the time zone..."
ln -sf /usr/share/zoneinfo/Region/City /etc/localtime
# Replace "Region" and "City" with your actual time zone, e.g., "America/New_York"

# Prompt for locale selection
print_message "Available locales:"
cat /etc/locale.gen
echo

read -p "Enter the desired locale from the above list (e.g., en_US.UTF-8): " selected_locale
echo "$selected_locale" > /etc/locale.conf
locale-gen

# Prompt for keyboard layout selection
print_message "Available keyboard layouts:"
ls /usr/share/kbd/keymaps/**/*.map.gz
echo

read -p "Enter the desired keyboard layout from the above list (e.g., us): " keyboard_layout
echo "KEYMAP=$keyboard_layout" > /etc/vconsole.conf

# Set the hostname
print_message "Setting the hostname..."
read -p "Enter the hostname for the system: " hostname
echo "$hostname" > /etc/hostname

# Install and configure NetworkManager
print_message "Installing and configuring NetworkManager..."
pacman -S networkmanager
systemctl enable NetworkManager

# Install GNOME desktop environment and necessary apps
print_message "Installing GNOME desktop environment and necessary apps..."
pacman -S gnome gnome-extra

# Create a new user
print_message "Creating a new user..."
read -p "Enter the username for the new user: " username
useradd -m -G wheel $username

# Prompt for sudo privileges
read -p "Do you want to grant sudo privileges to the user? (y/n): " sudo_option
if [[ $sudo_option == "y" || $sudo_option == "Y" ]]; then
    echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
    echo "Sudo privileges granted to $username."
else
    echo "Sudo privileges not granted to $username."
fi

# Install yay (AUR helper)
print_message "Installing yay (AUR helper)..."
su - $username -c "git clone https://aur.archlinux.org/yay.git /tmp/yay && cd /tmp/yay && makepkg -si --noconfirm"

# Install Google Chrome using yay
print_message "Installing Google Chrome..."
su - $username -c "yay -S google-chrome --noconfirm"

print_message "Arch Linux installation and setup with GNOME desktop completed successfully!"
echo "Please exit the chroot environment by typing 'exit' and then reboot your system."
