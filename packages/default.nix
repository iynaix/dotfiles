{
  inputs,
  pkgs,
  ...
}:
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

  # ricing glue
  dotfiles-rs = callPackage ./dotfiles-rs { };
  dotfiles-hyprland = callPackage ./dotfiles-rs { wm = "hyprland"; };
  dotfiles-niri = callPackage ./dotfiles-rs { wm = "niri"; };
  dotfiles-mango = callPackage ./dotfiles-rs { wm = "mango"; };

  tela-dynamic-icon-theme = callPackage ./tela-dynamic-icon-theme { };

  distro-grub-themes-nixos = callPackage ./distro-grub-themes-nixos { };

  helium = callPackage ./helium { };

  hyprnstack = callPackage ./hyprnstack { };

  nsw = callPackage ./nsw { };

  rofi-themes = callPackage ./rofi-themes { };
  rofi-power-menu = callPackage ./rofi-power-menu { };
  rofi-wifi-menu = callPackage ./rofi-wifi-menu { };

  tokyo-night-kvantum = callPackage ./tokyo-night-kvantum { };
}
