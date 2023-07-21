# Iynaix's Home Manager Config

Note that graphical programs compiled for NixOS tend to have issues running on other Linuxes as they can't find the right shared libraries. A possible workaround is to use [nixGL](https://github.com/guibou/nixGL). The graphical programs needed to be installed using the host OS are [listed below](#graphical-programs-wip).

### Install Nix on Other Linux Distros

```sh
sh <(curl -L https://nixos.org/nix/install) --daemon
```

### Install Home Manger

```sh
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
```

### Run Home Manger

Substitute `desktop` with desired host

```sh
mkdir -p ~/projects
git clone https://github.com/iynaix/dotfiles
cd dotfiles
nix-shell -p home-manager
home-manager --extra-experimental-features "nix-command flakes" switch --flake ".#desktop"
```

### Graphical Programs (WIP)

Hyprland / Wayland related
```
grimblast
hyprland
hyprprop
swww
waybar
```

General use
```
brave
deadbeef
ffmpeg
firefox
libreoffice
vlc
```

### TODO
- gtk fonts, cursor and theme don't seem to be working