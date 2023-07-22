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
git clone https://github.com/iynaix/dotfiles
cd dotfiles
rm ~/.config/gtk-3.0/bookmarks
nix-shell -p home-manager
NIXPKGS_ALLOW_UNFREE=1 home-manager --extra-experimental-features "nix-command flakes" switch --flake ".#desktop"
```

Reboot.

### Post Install

- Install `kitty` on the host OS, the nix package requires [nixGL](https://github.com/guibou/nixGL) to run.

### TODO
- gtk theme doesn't seem to be working
- use zsh package from host instead?
- hyprland stuff
  - grimblast
  - hyprland
  - hyprprop
  - swww
  - waybar