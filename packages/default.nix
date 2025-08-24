{
  inputs,
  pkgs,
  ...
}:
let
  inherit (pkgs) callPackage;
  repo_url = "https://raw.githubusercontent.com/iynaix/dotfiles";
in
rec {
  default = install;

  install = pkgs.writeShellApplication {
    name = "iynaixos-install";
    runtimeInputs = [ pkgs.curl ];
    text = # sh
      "sh <(curl -L ${repo_url}/main/install.sh)";
  };

  recover = pkgs.writeShellApplication {
    name = "iynaixos-recover";
    runtimeInputs = [ pkgs.curl ];
    text = # sh
      "sh <(curl -L ${repo_url}/main/recover.sh)";
  };

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

  # custom tela built with catppucin variant colors
  tela-dynamic-icon-theme = callPackage ./tela-dynamic-icon-theme {
    colors = {
      blue = "#89b4fa";
      flamingo = "#f2cdcd";
      green = "#a6e3a1";
      lavender = "#b4befe";
      maroon = "#eba0ac";
      mauve = "#cba6f7";
      peach = "#fab387";
      pink = "#f5c2e7";
      red = "#f38ba8";
      rosewater = "#f5e0dc";
      sapphire = "#74c7ec";
      sky = "#89dceb";
      teal = "#94e2d5";
      yellow = "#f9e2af";
    };
  };

  distro-grub-themes-nixos = callPackage ./distro-grub-themes-nixos { };

  hyprnstack = callPackage ./hyprnstack { };
  hypr-darkwindow = callPackage ./hypr-darkwindow { };

  path-of-building = callPackage ./path-of-building { };

  # mpv plugins
  mpv-cut = callPackage ./mpv-cut { };
  mpv-deletefile = callPackage ./mpv-deletefile { };
  mpv-nextfile = callPackage ./mpv-nextfile { };
  mpv-sub-select = callPackage ./mpv-sub-select { };
  mpv-subsearch = callPackage ./mpv-subsearch { };

  # for nixos-rebuild
  hsw = callPackage ./hsw { };
  nsw = callPackage ./nsw { };

  rofi-themes = callPackage ./rofi-themes { };
  rofi-power-menu = callPackage ./rofi-power-menu { };
  rofi-wifi-menu = callPackage ./rofi-wifi-menu { };
}
