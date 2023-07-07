# Iynaix's Nix Config

## How to Install
Remove old zfs pools (if necessary)
```sh
sudo zpool import
sudo zpool labelclear <numeric id>
```
### Setup ZFS
```sh
sh <(curl -L https://raw.githubusercontent.com/iynaix/dotfiles/main/zfs.sh)
```
### Install from Flake

Change `desktop` to desired host as needed

```sh
nix-shell -p nixFlakes
sudo nixos-install --flake github:iynaix/dotfiles#desktop --root /mnt
```

### Create Password Files for User and Root

This is not needed if restoring from persist snapshot (see below)

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