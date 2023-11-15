#!/usr/bin/env bash

set -e

function yesno() {
    local prompt="$1"

    while true; do
        read -rp "$prompt [y/n] " yn
        case $yn in
            [Yy]* ) echo "y"; return;;
            [Nn]* ) echo "n"; return;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

reformat_boot=$(yesno "Reformat boot?")
if [[ $reformat_boot == "y" ]]; then
    BOOTDISK=/dev/disk/by-label/NIXBOOT
    sudo mkfs.fat -F 32 "$BOOTDISK"
    sudo fatlabel "$BOOTDISK" NIXBOOT
fi

echo "Importing zpool"
sudo zpool import -f zroot

reformat_nix=$(yesno "Reformat nix?")
if [[ $reformat_nix == "y" ]]; then
    sudo zfs destroy -r zroot/local/nix

    sudo zfs create -o mountpoint=legacy zroot/local/nix
    sudo mkdir -p /mnt/nix
    sudo mount -t zfs zroot/local/nix /mnt/nix
fi

echo "Mounting Disks"

sudo mount -t zfs zroot/local/root /mnt
sudo mount $BOOTDISK /mnt/boot
sudo mount -t zfs zroot/local/nix /mnt/nix
sudo mount -t zfs zroot/local/tmp /mnt/tmp
sudo mount -t zfs zroot/safe/home /mnt/home
sudo mount -t zfs zroot/safe/persist /mnt/persist

echo "Installing NixOS"
while true; do
    read -rp "Which host to install? (desktop / framework / xps / vm) " host
    case $host in
        desktop|framework|xps|vm ) break;;
        * ) echo "Invalid host. Please select a valid host.";;
    esac
done

sudo nix-shell -p nixFlakes --command "nixos-install --root /mnt --flake \"github:iynaix/dotfiles#$host\"; return"