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

# Disk partitioning
bold_echo "Automatically partitioning the disk..."
parted -s /dev/sda mklabel gpt
parted -s /dev/sda mkpart primary 1MiB 512MiB   # EFI System Partition (ESP)
parted -s /dev/sda set 1 boot on
parted -s /dev/sda mkpart primary 512MiB 100%   # Root partition

# Format partitions
mkfs.vfat -F32 /dev/sda1
mkfs.btrfs /dev/sda2

# Mount the root partition
mount /dev/sda2 /mnt

# Create subvolumes for root partition
btrfs su cr /mnt/@
btrfs su cr /mnt/@home
btrfs su cr /mnt/@var

# Mount the subvolumes
umount /mnt
mount -o noatime,compress=zstd,space_cache=v2,subvol=@ /dev/sda2 /mnt
mkdir -p /mnt/{boot/efi,home,var}
mount -o noatime,compress=zstd,space_cache=v2,subvol=@home /dev/sda2 /mnt/home
mount -o noatime,compress=zstd,space_cache=v2,subvol=@var /dev/sda2 /mnt/var

# Install the base system and necessary packages
pacstrap /mnt base base-devel linux linux-firmware btrfs-progs sudo grub networkmanager

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot into the new system
arch-chroot /mnt /bin/bash <<EOF

# Prompt for setting the timezone
bold_echo "Set your timezone:"
bold_echo "1. London"
bold_echo "2. Other (You will need to provide the timezone path)"
read -p "Enter your choice (1/2): " timezone_choice

if [ "\$timezone_choice" == "1" ]; then
  ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
else
  # Uncomment and set the desired timezone path
  # ln -sf /usr/share/zoneinfo/Region/City /etc/localtime
  # Example: ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
  bold_echo "Please set the timezone manually by editing /etc/localtime."
fi

hwclock --systohc --utc

# Set the locale to UK
echo "en_GB.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_GB.UTF-8" > /etc/locale.conf

# Set the keyboard layout to UK
echo "KEYMAP=uk" > /etc/vconsole.conf

# Set the hostname
read -p "Enter your desired hostname: " hostname
echo "\$hostname" > /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 \$hostname.localdomain \$hostname" >> /etc/hosts

# Install and configure GRUB bootloader
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=arch_grub
grub-mkconfig -o /boot/grub/grub.cfg

# Install GNOME Desktop Environment
case "$desktop_choice" in
  1) # GNOME
    pacman -S gnome gnome-extra
    ;;
  2) # KDE
    pacman -S plasma kde-applications
    ;;
  3) # XFCE
    pacman -S xfce4 xfce4-goodies
    ;;
  *) # Default to GNOME
    pacman -S gnome gnome-extra
    ;;
esac

# Prompt for creating a user with sudo access
read -p "Enter a username for the new user: " username
useradd -m -G wheel \$username
passwd \$username
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

EOF

# Unmount all partitions and reboot
umount -R /mnt
reboot
