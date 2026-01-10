{ inputs, pkgs, ... }:
let
  inherit (pkgs) callPackage;
in
{
  # full neovim with nixd setup (requires path to dotfiles repo)
  neovim-iynaix = pkgs.callPackage (
    {
      dots ? null,
      host ? "desktop",
    }:
    (inputs.nvf.lib.neovimConfiguration {
      inherit pkgs;
      modules = [ ./neovim-iynaix ];
      extraSpecialArgs = { inherit dots host; };
    }).neovim
  ) { };

  dotfiles-rs = callPackage ./dotfiles-rs/wrapped.nix {
    dotfiles-rs-unwrapped = callPackage ./dotfiles-rs { };
  };

  tela-dynamic-icon-theme = callPackage ./tela-dynamic-icon-theme { };

  distro-grub-themes-nixos = callPackage ./distro-grub-themes-nixos { };

  awakened-poe-trade = callPackage ./awakened-poe-trade { };
  exiled-exchange-2 = callPackage ./exiled-exchange-2 { };

  helium = callPackage ./helium { };

  hyprnstack = callPackage ./hyprnstack { };

  nsw = callPackage ./nsw { };

  rofi-themes = callPackage ./rofi-themes { };

  tokyo-night-kvantum = callPackage ./tokyo-night-kvantum { };
}
