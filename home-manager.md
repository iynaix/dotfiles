# Iynaix's Home Manager Config

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
cd ~/projects
git clone https://github.com/iynaix/dotfiles
cd dotfiles
nix-shell -p home-manager
NIXPKGS_ALLOW_UNFREE=1 home-manager --extra-experimental-features "nix-command flakes" switch --flake ".#desktop"
```

Reboot.

### Post Install

- Install `kitty` on the host OS, the nix package requires [nixGL](https://github.com/guibou/nixGL) to run.

### TODO
- gtk theme doesn't seem to be working
- hyprland stuff
  - hyprland
  - swww
  - waybar