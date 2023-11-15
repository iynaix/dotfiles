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

cat << Introduction
This script will format the *entire* disk with a 1GB boot partition
(labelled NIXBOOT), 16GB of swap, then allocating the rest to ZFS.

The following ZFS datasets will be created:
    - zroot/local/root (mounted at / with blank snapshot)
    - zroot/local/nix (mounted at /nix)
    - zroot/local/tmp (mounted at /tmp)
    - zroot/safe/home (mounted at /home with blank snapshot)
    - zroot/safe/persist (mounted at /persist)

Introduction

# in a vm, special case
if [[ -b "/dev/vda" ]]; then
DISK="/dev/vda"

BOOTDISK="${DISK}3"
SWAPDISK="${DISK}2"
ZFSDISK="${DISK}1"
# normal disk
else
cat << FormatWarning
Please enter the disk by id to be formatted *without* the part number.
(e.g. nvme-eui.0123456789). Your devices are shown below:

FormatWarning

ls -al /dev/disk/by-id

echo ""

read -r DISKINPUT

DISK="/dev/disk/by-id/${DISKINPUT}"

BOOTDISK="${DISK}-part3"
SWAPDISK="${DISK}-part2"
ZFSDISK="${DISK}-part1"
fi

echo "Boot Partiton: $BOOTDISK"
echo "SWAP Partiton: $SWAPDISK"
echo "ZFS Partiton: $ZFSDISK"

do_format=$(yesno "This irreversibly formats the entire disk. Are you sure?")
if [[ $do_format == "n" ]]; then
    exit
fi

echo "Creating partitions"
sudo sgdisk -Z "$DISK"
sudo wipefs -a "$DISK"

sudo sgdisk -n3:1M:+1G -t3:EF00 "$DISK"
sudo sgdisk -n2:0:+16G -t2:8200 "$DISK"
sudo sgdisk -n1:0:0 -t1:BF01 "$DISK"

# notify kernel of partition changes
sudo sgdisk -p "$DISK" > /dev/null
sleep 5

echo "Creating Swap"
sudo mkswap "$SWAPDISK"
sudo swaplabel --label "SWAP" "$SWAPDISK"
sudo swapon "$SWAPDISK"

echo "Creating Boot Disk"
sudo mkfs.fat -F 32 "$BOOTDISK"
sudo fatlabel "$BOOTDISK" NIXBOOT

# setup encryption
use_encryption=$(yesno "Use encryption? (Encryption must also be enabled within host config.)")
if [[ $use_encryption == "y" ]]; then
    encryption_options="-O encryption=aes-256-gcm \
        -O keyformat=passphrase \
        -O keylocation=prompt"
else
    encryption_options=""
fi

echo "Creating base zpool"
sudo zpool create -f \
    -o ashift=12 \
    -o autotrim=on \
    -O compression=zstd \
    -O acltype=posixacl \
    -O atime=off \
    -O xattr=sa \
    -O normalization=formD \
    -O mountpoint=none \
    "$encryption_options" \
    zroot "$ZFSDISK"

# create top level datasets
sudo zfs create -o mountpoint=legacy zroot/local
sudo zfs create -o mountpoint=legacy zroot/safe

echo "Creating /"
sudo zfs create -o mountpoint=legacy zroot/local/root
sudo zfs snapshot zroot/local/root@blank
sudo mount -t zfs zroot/local/root /mnt

echo "Mounting /boot (efi)"
sudo mkdir -p /mnt/boot
sudo mount "$BOOTDISK" /mnt/boot

echo "Creating /nix"
sudo zfs create -o mountpoint=legacy zroot/local/nix
sudo mkdir -p /mnt/nix
sudo mount -t zfs zroot/local/nix /mnt/nix

echo "Creating /tmp"
sudo zfs create -o mountpoint=legacy zroot/local/tmp
sudo mkdir -p /mnt/tmp
sudo mount -t zfs zroot/local/tmp /mnt/tmp

echo "Creating /home"
sudo zfs create -o mountpoint=legacy zroot/safe/home
sudo zfs snapshot zroot/safe/home@blank
sudo mkdir -p /mnt/home
sudo mount -t zfs zroot/safe/home /mnt/home

echo "Creating /persist"
sudo zfs create -o mountpoint=legacy zroot/safe/persist
sudo mkdir -p /mnt/persist
sudo mount -t zfs zroot/safe/persist /mnt/persist

restore_snapshot=$(yesno "Do you want to restore from a persist snapshot?")
if [[ $restore_snapshot == "y" ]]; then
    echo "Enter full path to snapshot: "
    read -r snapshot_file_path
    echo
    sudo zfs receive -F zroot/safe/persist@persist-snapshot < "$snapshot_file_path"
else
    # no snapshot, prompt and write passwords to persist
    echo -n "Enter password: "
    read -rs password
    echo

    mkdir -p /persist/etc/shadow
    mkpasswd -m sha-512 "$password" 2>&1 > /dev/null | sudo tee -a /persist/etc/shadow/root
    mkpasswd -m sha-512 "$password" 2>&1 > /dev/null | sudo tee -a /persist/etc/shadow/iynaix
fi

echo "Installing NixOS"
while true; do
    read -rp "Which host to install? (desktop / framework / xps / vm) " host
    case $host in
        desktop|framework|xps|vm ) break;;
        * ) echo "Invalid host. Please select a valid host.";;
    esac
done

sudo nix-shell -p nixFlakes --command "nixos-install --root /mnt --flake \"github:iynaix/dotfiles#$host\"; return"