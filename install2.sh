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

# Get the list of disk devices
disk_list=$(lsblk -nlpo NAME)

# Check if any disks are available
if [ -z "$disk_list" ]; then
    echo "No disks found. Please make sure your disks are properly connected and run the script again."
    exit 1
fi

# Create an array to store the disk names
disks=()
for disk in $disk_list; do
    disks+=("$disk")
done

# List available disk drives with numbers
print_message "Available disk drives:"
for i in "${!disks[@]}"; do
    echo "$((i+1)). ${disks[i]}"
done
echo

# Prompt for disk selection
read -p "Enter the number of the disk to use for installation (e.g., 1, 2, etc.): " disk_num

# Check if the disk number is valid
if ! [[ "$disk_num" =~ ^[1-9]+$ ]] || [ "$disk_num" -gt "${#disks[@]}" ]; then
    echo "Invalid disk number. Please enter a valid number."
    exit 1
fi

# Get the disk corresponding to the chosen number
selected_disk=${disks[disk_num-1]}

# Check if the disk is an NVMe disk
if [[ "$selected_disk" == "/dev/nvme"* ]]; then
    # For NVMe disks, use "p" instead of the disk number for gdisk
    disk_partition="${selected_disk}p"
else
    disk_partition="${selected_disk}"
fi

# Delete existing partitions on the disk using gdisk
print_message "Deleting existing partitions on $selected_disk..."
gdisk $selected_disk << EOF
d
d
w
Y
EOF

# Partition the disk using gdisk
print_message "Partitioning the disk $selected_disk..."
gdisk $selected_disk << EOF
o
Y
n
1

+512M
EF00
n
2


8300
w
Y
EOF

# Format the EFI partition
print_message "Formatting the EFI partition..."
mkfs.fat -F32 ${selected_disk}1

# Format the root partition as btrfs
print_message "Formatting the root partition as btrfs..."
mkfs.btrfs -L arch ${selected_disk}2

# Mount the btrfs partition
print_message "Mounting the btrfs partition..."
mount ${selected_disk}2 /mnt

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
# Replace "Region" and "City" with your actual time zone, e.g., "Europe/London"

# Set the locale to UK (English UK)
echo "en_GB.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_GB.UTF-8" > /etc/locale.conf

# Set the keyboard layout to UK (English UK)
echo "KEYMAP=uk" > /etc/vconsole.conf

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
