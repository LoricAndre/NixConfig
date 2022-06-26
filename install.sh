#!/bin/sh

set -e

[ -z "$DISK" ] && echo 'Set $DISK variable to use script' && exit 1

PRIMARY="${DISK}1"
BOOT="${DISK}2"

# Helpers
p() {
  parted $DISK -- $@
}

# Partition disk
p mklabel gpt
p mkpart primary 512MiB 100%
p mkpart ESP fat32 1MiB 512MiB
p set 2 esp on

# Encryption
cryptsetup luksFormat $PRIMARY
cryptsetup luksOpen $BOOT cryptroot

# Filesystems
mkfs.ext4 -L nixos /dev/mapper/cryptroot
mkfs.fat -F 32 -n boot $BOOT
mount /dev/disk/by-label/nixos /mnt
mkdir /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot

# NixOS configuration. TODO: use custom config from this repo
nixos-generate-config --root /mnt
vim /mnt/etc/nixos/configuration.nix

# Install
nixos-install
reboot
