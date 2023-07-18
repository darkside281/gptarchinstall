#!/bin/bash

# Install Git
pacman -Syu --noconfirm git

# Update repositories
pacman -Syu

# Prompt for keyboard layout selection
echo "Choose your keyboard layout:"
echo "1) US"
echo "2) UK"
echo "3) DE"
echo "4) FR"
echo "5) ES"
read -p "Enter the number corresponding to your choice: " layout_choice

case $layout_choice in
    1)
        KEYBOARD_LAYOUT="us"
        ;;
    2)
        KEYBOARD_LAYOUT="uk"
        ;;
    3)
        KEYBOARD_LAYOUT="de"
        ;;
    4)
        KEYBOARD_LAYOUT="fr"
        ;;
    5)
        KEYBOARD_LAYOUT="es"
        ;;
    *)
        echo "Invalid choice. Using default layout 'us'."
        KEYBOARD_LAYOUT="us"
        ;;
esac

# Connect to the internet
# For wired connection, DHCP is used by default
# For wireless connection, use wifi-menu or other suitable tools

# Check for the best mirrors
echo "Checking for the best mirrors..."
reflector --latest 10 --sort rate --save /etc/pacman.d/mirrorlist

# Update the system clock
timedatectl set-ntp true

# Prompt for the drive to partition
read -p "Enter the drive to partition (e.g., /dev/sda): " DRIVE

# Confirmation prompt for wiping the drive
read -p "WARNING: The drive '$DRIVE' will be wiped. Do you want to continue? (y/N): " WIPE_CONFIRMATION

if [[ ! $WIPE_CONFIRMATION =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# Partition the drive
sgdisk --zap-all "$DRIVE"
sgdisk -n 1:0:1G -t 1:ef00 "$DRIVE" # EFI partition
sgdisk -n 2:0:0 -t 2:8300 "$DRIVE"  # BTRFS partition
sgdisk -n 3:0:4G -t 3:8200 "$DRIVE" # Swap partition

# Format the partitions
mkfs.fat -F32 "${DRIVE}1"   # EFI partition
mkfs.btrfs "${DRIVE}2"      # BTRFS partition
mkswap "${DRIVE}3"          # Swap partition

# Mount the BTRFS partition
mount "${DRIVE}2" /mnt

# Create subvolumes
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
umount /mnt

# Mount subvolumes
mount -o noatime,compress=zstd,subvol=@ "${DRIVE}2" /mnt
mkdir /mnt/home
mount -o noatime,compress=zstd,subvol=@home "${DRIVE}2" /mnt/home

# Enable swap
swapon "${DRIVE}3"

# Install essential packages
pacstrap /mnt base base-devel linux linux-firmware btrfs-progs xf86-video-intel

# Generate an fstab file
genfstab -U /mnt >> /mnt/etc/fstab

# Change root into the new system
arch-chroot /mnt /bin/bash <<EOF

# Set the keyboard layout
echo "KEYMAP=$KEYBOARD_LAYOUT" > /etc/vconsole.conf

# Set the time zone
echo "Choose your time zone:"
echo "1) America/New_York"
echo "2) Europe/London"
echo "3) Europe/Berlin"
echo "4) Europe/Paris"
echo "5) America/Los_Angeles"
read -p "Enter the number corresponding to your choice: " timezone_choice

case \$timezone_choice in
    1)
        TIME_ZONE="America/New_York"
        ;;
    2)
        TIME_ZONE="Europe/London"
        ;;
    3)
        TIME_ZONE="Europe/Berlin"
        ;;
    4)
        TIME_ZONE="Europe/Paris"
        ;;
    5)
        TIME_ZONE="America/Los_Angeles"
        ;;
    *)
        echo "Invalid choice. Using default time zone 'America/New_York'."
        TIME_ZONE="America/New_York"
        ;;
esac

ln -sf "/usr/share/zoneinfo/\$TIME_ZONE" /etc/localtime
hwclock --systohc

# Set the system localization
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Set the hostname
read -p "Enter your desired hostname: " HOSTNAME
echo "$HOSTNAME" > /etc/hostname

# Configure the network
# Add your network configuration here if needed

# Set the root password
read -s -p "Enter the root password: " ROOT_PASSWORD
echo "root:$ROOT_PASSWORD" | chpasswd

# Create a new user
read -p "Enter the username for the new user: " USERNAME
useradd -m -G wheel -s /bin/bash "$USERNAME"
echo "$USERNAME:$ROOT_PASSWORD" | chpasswd

# Prompt for sudo privileges
read -p "Do you want to give '$USERNAME' sudo privileges? (y/N): " SUDO_CHOICE

if [[ \$SUDO_CHOICE =~ ^[Yy]$ ]]; then
    sed -i '/%wheel ALL=(ALL) ALL/s/^# //' /etc/sudoers
fi

# Install systemd-boot
bootctl install

# Create systemd-boot entry for Arch Linux
cat <<EOF > /boot/loader/entries/arch.conf
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=UUID=$(blkid -s UUID -o value "${DRIVE}2") rw
EOF

# Create systemd-boot entry for Backup Kernel
cat <<EOF > /boot/loader/entries/arch-backup.conf
title Arch Linux (Backup)
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=UUID=$(blkid -s UUID -o value "${DRIVE}2") rw
EOF

# Configure systemd-boot
cat <<EOF > /boot/loader/loader.conf
default arch
timeout 3
editor 0
EOF

# Install BTRFS tools for system management
pacman -Syu btrfs-progs

# Install GNOME packages
pacman -Syu gnome gnome-extra

# Install additional packages
pacman -Syu libreoffice-fresh gparted gimp pulseaudio pulseaudio-alsa

# Install common drivers
pacman -Syu xf86-input-synaptics xf86-input-libinput xorg-drivers

# Enable and start NetworkManager
systemctl enable NetworkManager
systemctl start NetworkManager

# Enable GNOME Display Manager (GDM)
systemctl enable gdm.service

# Configure Power Management (example: enable suspend on lid close)
echo "HandleLidSwitch=suspend" >> /etc/systemd/logind.conf

# Install yay
pacman -Syu --needed git base-devel
git clone https://aur.archlinux.org/yay.git /tmp/yay
cd /tmp/yay
makepkg -si --noconfirm
cd ~

# Install Pamac dependencies
pacman -Syu --needed polkit-gnome gnome-keyring

# Install Pamac
yay -Syu pamac-aur

EOF

# Unmount all partitions
umount -R /mnt

# Reboot the system
reboot
