#!/bin/bash

# Function to print messages in bold
function bold_echo {
  echo -e "\033[1m$1\033[0m"
}

# Prompt for Desktop Environment Selection
bold_echo "Choose Desktop Environment:"
bold_echo "1. GNOME"
bold_echo "2. KDE"
bold_echo "3. XFCE"
read -p "Enter your choice (1/2/3): " desktop_choice

# Partition the disk using cfdisk
bold_echo "Partition the disk using cfdisk. Make sure to create a root partition and a swap partition."
cfdisk

# Prompt for Partition Selection
read -p "Enter your root partition (e.g., /dev/sda1): " root_partition
read -p "Enter your swap partition (e.g., /dev/sda2): " swap_partition

# Format partitions
mkfs.btrfs $root_partition
mkswap $swap_partition
swapon $swap_partition

# Mount the root partition
mount $root_partition /mnt

# Create subvolumes for root partition
btrfs su cr /mnt/@
btrfs su cr /mnt/@home
btrfs su cr /mnt/@var

# Mount the subvolumes
umount /mnt
mount -o noatime,compress=zstd,space_cache=v2,subvol=@ $root_partition /mnt
mkdir -p /mnt/{boot/efi,home,var}
mount -o noatime,compress=zstd,space_cache=v2,subvol=@home $root_partition /mnt/home
mount -o noatime,compress=zstd,space_cache=v2,subvol=@var $root_partition /mnt/var

# Install the base system and necessary packages
pacstrap /mnt base base-devel linux linux-firmware btrfs-progs sudo grub networkmanager

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot into the new system
arch-chroot /mnt /bin/bash <<EOF

# Rest of the script remains the same

EOF

# Unmount all partitions and reboot
umount -R /mnt
swapoff $swap_partition
btrfs subvolume delete /mnt/@home
btrfs subvolume delete /mnt/@var
btrfs subvolume delete /mnt/@
btrfs filesystem delete /mnt
reboot
