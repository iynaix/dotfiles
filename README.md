# Iynaix's NixOS Config

This config is intended to be used with NixOS. There is *experimental* support for running the dotfiles on [legacy operating systems](https://github.com/iynaix/dotfiles/blob/main/home-manager.md).

## Features

- Multiple NixOS configurations, including desktop, laptops and VM
- Persistence via impermanence (both `/` and `/home`)
- Automatic ZFS snapshots with rotation
- Flexible NixOS / Home Manager config via feature flags
- sops-nix for managing secrets
- Hyprland / niri with waybar setup, with screen capture
- Dynamic colorschemes using wallust (pywal, but maintained)

## How to Install
Run the following commands from a terminal on a NixOS live iso / from a tty on the minimal iso.

The following install script partitions the disk, sets up the necessary datasets and installs NixOS.

From a standard ISO,
```sh
sh <(curl -L https://raw.githubusercontent.com/iynaix/dotfiles/main/install.sh)
```

From the custom iso built via `nbuild-iso ISO_HOST`,
```sh
iynaixos-install
```
Reboot

<details>
<summary><h4>Creating Persist Snapshot to Restore</h4></summary>

```sh
sudo zfs snapshot zroot/persist@persist-snapshot
sudo zfs send zroot/persist@persist-snapshot > SNAPSHOT_FILE_PATH
```
</details>

<details>
<summary><h4>Restoring from Persist Snapshot</h4></summary>

```sh
# the rename is needed for encrypted datasets, as -F doesn't work
sudo zfs receive -o mountpoint=legacy zroot/persist-new < SNAPSHOT_FILE_PATH
sudo zfs rename zroot/persist zroot/persist-old
sudo zfs rename zroot/persist-new zroot/persist
```
</details>

## System Rescue
Run the following commands from a terminal on a NixOS live iso / from a tty on the minimal iso.

The following script optionally reformats the boot partition and / or /nix dataset, then reinstalls NixOS.

From a standard ISO,
```sh
sh <(curl -L https://raw.githubusercontent.com/iynaix/dotfiles/main/recover.sh)
```

From the custom iso built via `nbuild-iso ISO_HOST`,
```sh
iynaixos-recover
```
