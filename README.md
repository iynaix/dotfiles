# Iynaix's NixOS Config

This config is intended to be used with NixOS. There is *experimental* support for running the dotfiles on [legacy operating systems](https://github.com/iynaix/dotfiles/blob/main/home-manager.md).

## Features

- Multiple NixOS configurations, including desktop, laptops and VM
- Persistence via impermanence (both `/` and `/home`)
- Automatic ZFS snapshots with rotation
- Flexible NixOS / Home Manager config via feature flags
- sops-nix for managing secrets
- Hyprland with waybar setup, with screen capture
- Dynamic colorschemes using wallust (pywal, but maintained)

## How to Install
Run the following commands from a terminal on a NixOS live iso / from a tty on the minimal iso.

The following install script partitions the disk, sets up the necessary datasets and installs NixOS.

```sh
sh <(curl -L https://raw.githubusercontent.com/iynaix/dotfiles/main/install.sh)
```
Reboot

### Creating Persist Snapshot to Restore

```sh
sudo zfs snapshot zroot/safe/persist@persist-snapshot
sudo zfs send zroot/safe/persist@persist-snapshot > SNAPSHOT_FILE_PATH
```

# System Rescue for Bootloader
Run the following commands from a terminal on a NixOS live iso / from a tty on the minimal iso.

The following script optionally reformats the boot partition and / or /nix dataset, then reinstalls NixOS.

```sh
sh <(curl -L https://raw.githubusercontent.com/iynaix/dotfiles/main/recover.sh)
```