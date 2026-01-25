{ pkgs, ... }:
{
  # full neovim with nixd setup (requires path to dotfiles repo)
  dotfiles-rs = pkgs.callPackage ./dotfiles-rs/wrapped.nix {
    dotfiles-rs-unwrapped = pkgs.callPackage ./dotfiles-rs { };
  };

  tela-dynamic-icon-theme = pkgs.callPackage ./tela-dynamic-icon-theme { };

  distro-grub-themes-nixos = pkgs.callPackage ./distro-grub-themes-nixos { };

  awakened-poe-trade = pkgs.callPackage ./awakened-poe-trade { };
  exiled-exchange-2 = pkgs.callPackage ./exiled-exchange-2 { };

  helium = pkgs.callPackage ./helium { };

  hyprnstack = pkgs.callPackage ./hyprnstack { };

  nsw = pkgs.callPackage ./nsw { };

  rofi-themes = pkgs.callPackage ./rofi-themes { };

  tokyo-night-kvantum = pkgs.callPackage ./tokyo-night-kvantum { };
}
