#!/bin/bash

# Update the system's package repositories
sudo pacman -Sy

# Install required packages
sudo pacman -S --needed base-devel git

# Choose a directory for cloning the Surface kernel repository
kernel_directory="$HOME/linux-surface"

# Clone the Surface kernel repository if it doesn't exist, or update it if it already exists
if [ -d "$kernel_directory" ]; then
  echo "Updating the existing Surface kernel repository..."
  cd "$kernel_directory"
  git pull
else
  echo "Cloning the Surface kernel repository..."
  git clone https://github.com/linux-surface/linux-surface.git "$kernel_directory"
  cd "$kernel_directory"
fi

# Build and install the Surface kernel
echo "Building and installing the Surface kernel..."
makepkg -si

# Clean up the temporary files
echo "Cleaning up..."
make clean

echo "Kernel installation completed successfully!"
