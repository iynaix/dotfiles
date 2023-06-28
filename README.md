# Iynaix's Nix Config

## How to Install
### Remove old zfs pools (if necessary)
```sh
sudo zpool import
sudo zpool labelclear <numeric id>
```
### Setup zfs
```sh
sh <(curl -L https://raw.githubusercontent.com/iynaix/dotfiles/main/zfs.sh)
```
### Install from flake

Change `desktop` to desired host as needed

```sh
nix-shell -p nixFlakes
sudo nixos-install --flake github:iynaix/dotfiles#desktop --root /mnt
```
