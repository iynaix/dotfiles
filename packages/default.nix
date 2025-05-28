{
  inputs,
  pkgs,
  ...
}:
let
  inherit (pkgs) lib callPackage;
  # injects a source parameter from nvfetcher
  # adapted from viperML's config
  # https://github.com/viperML/dotfiles/blob/master/packages/default.nix
  w =
    _callPackage: path: extraOverrides:
    let
      sources = pkgs.callPackages (path + "/generated.nix") { };
      firstSource = lib.head (lib.attrValues sources);
    in
    _callPackage (path + "/default.nix") (
      extraOverrides // { source = lib.filterAttrs (k: _: !(lib.hasPrefix "override" k)) firstSource; }
    );
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

  # custom tela built with catppucin variant colors
  tela-dynamic-icon-theme = callPackage ./tela-dynamic-icon-theme { };

  distro-grub-themes-nixos = callPackage ./distro-grub-themes-nixos { };

  hyprnstack = callPackage ./hyprnstack { };
  hypr-darkwindow = callPackage ./hypr-darkwindow { };

  path-of-building = w callPackage ./path-of-building { };

  # mpv plugins
  mpv-cut = w pkgs.mpvScripts.callPackage ./mpv-cut { };
  mpv-deletefile = w pkgs.mpvScripts.callPackage ./mpv-deletefile { };
  mpv-nextfile = w pkgs.mpvScripts.callPackage ./mpv-nextfile { };
  mpv-sub-select = w pkgs.mpvScripts.callPackage ./mpv-sub-select { };
  mpv-subsearch = w pkgs.mpvScripts.callPackage ./mpv-subsearch { };

  # for nixos-rebuild
  hsw = callPackage ./hsw { };
  nsw = callPackage ./nsw { };

  rofi-themes = w callPackage ./rofi-themes { };
  rofi-power-menu = callPackage ./rofi-power-menu { };
  rofi-wifi-menu = callPackage ./rofi-wifi-menu { };
}
