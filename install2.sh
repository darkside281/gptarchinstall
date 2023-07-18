#!/bin/bash

# Check if the script is being run as root
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root."
  exit 1
fi

read -p "Enter the drive (e.g., /dev/sda) to wipe and partition as Btrfs: " drive

# Prompt for the timezone (Region/City format)
read -p "Enter your timezone (Region/City): " timezone

# Prompt for the hostname
read -p "Enter your desired hostname: " hostname

# Prompt for the username
read -p "Enter the username for the new user: " username

# Wipe the drive and create Btrfs, swap, and EFI partitions
wipefs -a "$drive"
parted -s "$drive" mklabel gpt
parted -s "$drive" mkpart primary 1MiB 512MiB  # EFI partition
parted -s "$drive" set 1 esp on
parted -s "$drive" mkpart primary 512MiB 100%  # Btrfs partition
parted -s "$drive" set 2 raid on

# Format and mount the partitions
mkfs.vfat -F32 "${drive}1"  # EFI partition
mkfs.btrfs "${drive}2"      # Btrfs partition
mount "${drive}2" /mnt
btrfs subvolume create /mnt/root
umount /mnt

# Mount the Btrfs subvolume and create necessary directories
mount -o noatime,compress=lzo,space_cache,subvol=root "${drive}2" /mnt
mkdir /mnt/{boot,efi}
mount "${drive}1" /mnt/efi

# Install the base system and necessary packages
pacstrap /mnt base base-devel linux linux-firmware btrfs-progs nano

# Generate an Fstab file
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot into the newly installed system
arch-chroot /mnt /bin/bash <<EOF
# Set timezone
ln -sf /usr/share/zoneinfo/"$timezone" /etc/localtime
hwclock --systohc

# Set locale
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Set hostname
echo "$hostname" > /etc/hostname

# Set up network (if wired connection)
systemctl enable dhcpcd.service

# Set up bootloader (GRUB)
pacman -S grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=arch_grub
grub-mkconfig -o /boot/grub/grub.cfg

# Install GNOME and additional packages for full desktop experience
pacman -S gnome gnome-extra networkmanager
systemctl enable gdm
systemctl enable NetworkManager

# Create a new user and set the password
useradd -m -G wheel "$username"
passwd "$username"

# Enable sudo access for the new user
echo "$username ALL=(ALL) ALL" >> /etc/sudoers

# Exit the chroot environment
exit
EOF

# Unmount all partitions and reboot
umount -R /mnt
reboot
