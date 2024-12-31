#!/bin/bash

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" 
    exit 1
fi

# Define the target drive
DRIVE="/dev/nvme0n1"

# Create partition table
parted ${DRIVE} -- mklabel gpt

# Create EFI partition
parted ${DRIVE} -- mkpart ESP fat32 1MiB 512MiB
parted ${DRIVE} -- set 1 esp on

# Create root partition
parted ${DRIVE} -- mkpart primary 512MiB 100%

# Format partitions
mkfs.fat -F 32 -n boot ${DRIVE}p1
mkfs.ext4 -L nixos ${DRIVE}p2

# Mount partitions
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot

# Generate NixOS configuration
nixos-generate-config --root /mnt

# Create a basic configuration file
cat > /mnt/etc/nixos/configuration.nix << 'EOF'
{ config, pkgs, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone
  time.timeZone = "UTC";

  # Enable sound
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enable X11 windowing system
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  # Define a user account
  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "nixos";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    firefox
  ];

  # Enable OpenSSH
  services.openssh.enable = true;

  system.stateVersion = "23.11";
}
EOF

# Install NixOS
nixos-install

echo "Installation complete! You can now reboot into your new NixOS system."
echo "Default user: nixos"
echo "Default password: nixos"
echo "Please change the password after first login."
