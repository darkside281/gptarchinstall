#!/bin/bash

# Function to print messages in bold
function bold_echo {
  echo -e "\033[1m$1\033[0m"
}

# Function to handle errors and prompt for retry/exit
function handle_error {
  bold_echo "Error: $1"
  read -p "Do you want to fix the issue and retry? (y/n): " choice
  if [ "$choice" == "y" ]; then
    return 0
  else
    exit 1
  fi
}

# Prompt for Desktop Environment Selection
bold_echo "Choose Desktop Environment:"
bold_echo "1. GNOME"
bold_echo "2. KDE"
bold_echo "3. XFCE"
read -p "Enter your choice (1/2/3): " desktop_choice

# Prompt for Partition Selection
bold_echo "Make sure you have already partitioned your disk!"
read -p "Enter your root partition (e.g., /dev/sda1): " root_partition
read -p "Enter your swap partition (e.g., /dev/sda2): " swap_partition

# Format partitions
bold_echo "Formatting the root partition..."
mkfs.btrfs $root_partition || handle_error "Failed to format the root partition"

bold_echo "Creating swap..."
mkswap $swap_partition || handle_error "Failed to create swap"

bold_echo "Enabling swap..."
swapon $swap_partition || handle_error "Failed to enable swap"

# Mount the root partition
mount $root_partition /mnt || handle_error "Failed to mount the root partition"

# Create subvolumes for root partition
bold_echo "Creating subvolumes..."
btrfs su cr /mnt/@ || handle_error "Failed to create subvolume @"

btrfs su cr /mnt/@home || handle_error "Failed to create subvolume @home"
btrfs su cr /mnt/@var || handle_error "Failed to create subvolume @var"

# Mount the subvolumes
bold_echo "Mounting subvolumes..."
umount /mnt || handle_error "Failed to unmount /mnt"

mount -o noatime,compress=zstd,space_cache=v2,subvol=@ $root_partition /mnt || handle_error "Failed to mount the root subvolume @"

mkdir -p /mnt/{boot/efi,home,var} || handle_error "Failed to create directories"

mount -o noatime,compress=zstd,space_cache=v2,subvol=@home $root_partition /mnt/home || handle_error "Failed to mount subvolume @home"

mount -o noatime,compress=zstd,space_cache=v2,subvol=@var $root_partition /mnt/var || handle_error "Failed to mount subvolume @var"

# Install the base system and necessary packages
bold_echo "Installing base system..."
pacstrap /mnt base base-devel linux linux-firmware btrfs-progs sudo grub networkmanager || handle_error "Failed to install the base system and packages"

# Generate fstab
bold_echo "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab || handle_error "Failed to generate fstab"

# Chroot into the new system
arch-chroot /mnt /bin/bash <<EOF

# Rest of the script remains the same

EOF

# Unmount all partitions and reboot
umount -R /mnt
reboot
