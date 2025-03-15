# Iynaix's Home Manager Config

### Install Nix on Other Linux Distros

```sh
sh <(curl -L https://nixos.org/nix/install) --daemon
```

### Install Home Manager

```sh
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
```

### Run Home Manager

Substitute `desktop` with desired host

```sh
mkdir -p ~/projects
cd ~/projects
git clone https://github.com/iynaix/dotfiles
cd dotfiles
nix-shell -p home-manager
NIXPKGS_ALLOW_UNFREE=1 home-manager --extra-experimental-features "nix-command flakes" switch --flake ".#desktop"
```

Reboot.

### TODO
- gtk theme doesn't seem to be working
- hyprland stuff
  - hyprland
  - swww
  - waybar