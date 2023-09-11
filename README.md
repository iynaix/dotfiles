# Iynaix's NixOS Config

This config is intended to be used with NixOS. There is *experimental* support for running the dotfiles on [legacy operating systems](https://github.com/iynaix/dotfiles/blob/main/home-manager.md).

## Features

- Multiple NixOS configurations, including desktop, laptop and VM
- Persistence via impermanence
- Automatic ZFS snapshots
- Flexible NixOS / Home Manager config via feature flags
- sops-nix for managing secrets
- Hyprland with waybar setup, with screen capture
- Dynamic colorschemes using wallust

## How to Install
Run the following commands from a terminal on a NixOS live iso / from a tty on the minimal iso.

### Setup ZFS
```sh
sh <(curl -L https://raw.githubusercontent.com/iynaix/dotfiles/main/zfs.sh)
```
### Install from Flake

Substitute `desktop` with desired host (desktop / laptop / vm)

```sh
nix-shell -p nixFlakes
sudo nixos-install --flake github:iynaix/dotfiles#desktop
```

### Create Password Files for User and Root

This is not needed if restoring from [persist snapshot](#restore-persist-from-snapshot)

```sh
mkdir -p /persist/etc/shadow
mkpasswd -m sha-512 'PASSWORD' | sudo tee -a /persist/etc/shadow/root
mkpasswd -m sha-512 'PASSWORD' | sudo tee -a /persist/etc/shadow/iynaix
```

### Restore Persist from Snapshot

```sh
sudo zfs snapshot zroot/safe/persist@persist-snapshot
sudo zfs send zroot/safe/persist@persist-snapshot > snapshot_file_path
sudo zfs receive -F zroot/safe/persist@persist-snapshot < snapshot_file_path
```