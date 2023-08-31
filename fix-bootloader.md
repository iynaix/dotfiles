# Fixing the Bootloader

### Reimport existing zpool
```sh
sudo zpool import
sudo zpool import <numeric_id>
```

### Format Boot Partition
Trying to follow the bootloader reinstall process from the [NixOS Wiki](https://nixos.wiki/wiki/Bootloader#From_an_installation_media) doesn't seem to work; erroring out on the `/boot` being a read-only filesystem. As a workaround, reformat the boot partition before remounting so that it can be written to.

```sh
ls -al /dev/disk/by-id
```

Set a `$BOOTDISK` variable and format the drive:

```sh
BOOTDISK=<disk>-part3
sudo mkfs.fat -F 32 $BOOTDISK
sudo fatlabel $BOOTDISK NIXBOOT
```

### Remount Partitions for Install

```sh
sudo mount -t zfs zroot/local/root /mnt
sudo mount $BOOTDISK /mnt/boot
sudo mount -t zfs zroot/local/nix /mnt/nix
sudo mount -t zfs zroot/local/tmp /mnt/tmp
sudo mount -t zfs zroot/safe/home /mnt/home
sudo mount -t zfs zroot/safe/persist /mnt/persist
```

### Reinstall from Flake

Check all partitions are mounted with `findmnt`

Change `desktop` to desired host as needed

```sh
nix-shell -p nixFlakes
sudo nixos-install --flake github:iynaix/dotfiles#desktop
```