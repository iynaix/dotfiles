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
    - zroot/root (mounted at / with blank snapshot)
    - zroot/nix (mounted at /nix)
    - zroot/tmp (mounted at /tmp)
    - zroot/persist (mounted at /persist)
    - zroot/persist/cache (mounted at /persist/cache)

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
sudo blkdiscard -f "$DISK"

sudo sgdisk -n3:1M:+1G -t3:EF00 "$DISK"
sudo sgdisk -n2:0:+16G -t2:8200 "$DISK"
sudo sgdisk -n1:0:0 -t1:BF01 "$DISK"

# notify kernel of partition changes
sudo sgdisk -p "$DISK" > /dev/null
sleep 5

echo "Creating Swap"
sudo mkswap "$SWAPDISK" --label "SWAP"
sudo swapon "$SWAPDISK"

echo "Creating Boot Disk"
sudo mkfs.fat -F 32 "$BOOTDISK" -n NIXBOOT

# setup encryption
use_encryption=$(yesno "Use encryption? (Encryption must also be enabled within host config.)")
if [[ $use_encryption == "y" ]]; then
    encryption_options=(-O encryption=aes-256-gcm -O keyformat=passphrase -O keylocation=prompt)
else
    encryption_options=()
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
    "${encryption_options[@]}" \
    zroot "$ZFSDISK"

echo "Creating /"
sudo zfs create -o mountpoint=legacy zroot/root
sudo zfs snapshot zroot/root@blank
sudo mount -t zfs zroot/root /mnt

# create the boot parition after creating root
echo "Mounting /boot (efi)"
sudo mount --mkdir "$BOOTDISK" /mnt/boot

echo "Creating /nix"
sudo zfs create -o mountpoint=legacy zroot/nix
sudo mount --mkdir -t zfs zroot/nix /mnt/nix

echo "Creating /tmp"
sudo zfs create -o mountpoint=legacy zroot/tmp
sudo mount --mkdir -t zfs zroot/tmp /mnt/tmp

echo "Creating /cache"
sudo zfs create -o mountpoint=legacy zroot/cache
sudo mount --mkdir -t zfs zroot/cache /mnt/cache

# handle persist, possibly from snapshot
restore_snapshot=$(yesno "Do you want to restore from a persist snapshot?")
if [[ $restore_snapshot == "y" ]]; then
    echo "Enter full path to snapshot: "
    read -r snapshot_file_path
    echo

    echo "Creating /persist"
    # disable shellcheck (sudo doesn't affect redirects)
    # shellcheck disable=SC2024
    sudo zfs receive -o mountpoint=legacy zroot/persist < "$snapshot_file_path"

else
    echo "Creating /persist"
    sudo zfs create -o mountpoint=legacy zroot/persist
fi
sudo mount --mkdir -t zfs zroot/persist /mnt/persist

while true; do
    read -rp "Which host to install? (desktop / framework / xps / vm / vm-amd) " host
    case $host in
        desktop|framework|xps|vm|vm-amd ) break;;
        * ) echo "Invalid host. Please select a valid host.";;
    esac
done

read -rp "Enter git rev for flake (default: main): " git_rev
echo "Installing NixOS"
sudo nixos-install --no-root-password --flake "github:iynaix/dotfiles/${git_rev:-main}#$host"