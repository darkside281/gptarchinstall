# Arch Linux Installation Script

This script automates the installation process of Arch Linux with the GNOME desktop environment. It sets up the system with BTRFS as the file system, creates subvolumes, configures the bootloader, installs essential packages, common drivers, and additional applications.

## Features

- Interactive prompts for keyboard layout selection, drive partitioning, time zone, hostname, and user creation
- Wiping of the selected drive with partitioning (EFI, BTRFS, and Swap)
- Mounting of BTRFS subvolumes and enabling swap
- Keyboard layout, time zone, localization, and hostname configuration
- Setting root and user passwords
- Optional sudo privileges for the user
- Installation of systemd-boot as the bootloader
- Installation of GNOME and its extra packages
- Installation of LibreOffice Fresh, GParted, GIMP, PulseAudio, and PulseAudio-ALSA
- Installation of common drivers (xf86-input-synaptics, xf86-input-libinput, xorg-drivers)
- Configuration of NetworkManager and GNOME Display Manager (GDM)
- Power management configuration (e.g., suspend on lid close)
- Installation of yay AUR package manager and Pamac package manager
- Display of installation progress as a percentage

## Usage

1. Boot into the Arch Linux installation media.
2. Connect to the internet:
   - For a wired connection, DHCP is used by default.
   - For a wireless connection, you can use the following command:
     - `wifi-menu` - This command opens a text-based interface for connecting to Wi-Fi networks. Follow the prompts to select and connect to your desired Wi-Fi network.

3. Clone or download this repository.
4. Make the script executable: `chmod +x arch_install.sh`.
5. Run the script with root privileges: `./arch_install.sh`.
6. Follow the prompts to configure the installation settings.
7. Sit back and let the script install Arch Linux with GNOME for you.

Note: It is recommended to review and customize the script according to your specific needs before running it.

## Requirements

- Arch Linux installation media
- Internet connection

## License

This project is licensed under the [MIT License](LICENSE).
