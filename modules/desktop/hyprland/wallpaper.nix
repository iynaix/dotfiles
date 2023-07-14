{
  pkgs,
  user,
  config,
  lib,
  ...
}: let
  cfg = config.iynaix.wallpaper;
  # sets up all the colors but DOES NOT change the wallpaper
  hypr-reset = pkgs.writeShellScriptBin "hypr-reset" ''
    # hyprland doesnt accept leading #
    source $HOME/.cache/wallust/colors-hexless.sh

    hyprctl keyword general:col.active_border "rgb($color4) rgb($color6) 45deg";
    hyprctl keyword general:col.inactive_border "rgb($color0)";

    # pink border for monocle windows
    hyprctl keyword windowrulev2 bordercolor "rgb($color5),fullscreen:1"
    # teal border for floating windows
    hyprctl keyword windowrulev2 bordercolor "rgb($color6),floating:1"
    # yellow border for sticky (must be floating) windows
    hyprctl keyword windowrulev2 bordercolor "rgb($color3),pinned:1"

    swww query || swww init
    if [ -z "$1" ]; then
      swww img --transition-type ${cfg.transition} "$wallpaper"
    else
      swww img --transition-type ${cfg.transition} "$1"
    fi
    wait

    launch-waybar
  '';
  # sets a random wallpaper and changes the colors
  hypr-wallpaper = pkgs.writeShellScriptBin "hypr-wallpaper" ''
    if [ -z "$1" ]; then
      wallpaper=$(random-wallpaper)
    else
      wallpaper="$1"
    fi
    wallust ${lib.optionalString (!config.iynaix.wallust.zsh) "--skip-sequences "} "$wallpaper"
    wait
    hypr-reset "$wallpaper"
  '';
in {
  options.iynaix.wallpaper = {
    # transition is type of left right top
    transition = lib.mkOption {
      type =
        lib.types.enum ["simple" "fade" "left" "right" "top" "bottom" "wipe" "wave" "grow" "center" "any" "outer" "random"];
      default = "grow";
      description = "The transition type for swww";
    };
  };

  config = {
    home-manager.users.${user} = {
      home = {
        packages = [
          hypr-reset
          hypr-wallpaper
          pkgs.swww
        ];
      };
    };

    # nixpkgs.overlays = [
    #   (self: super: {
    #     # creating an overlay for buildRustPackage overlay
    #     # https://discourse.nixos.org/t/is-it-possible-to-override-cargosha256-in-buildrustpackage/4393/3
    #     swww = super.swww.overrideAttrs (oldAttrs: rec {
    #       src = pkgs.fetchgit {
    #         url = "https://github.com/Horus645/swww";
    #         rev = "b7cde38a983740aae1dfe4e48fd3fc7e6d403fe0";
    #         sha256 = "sha256-9c/qBmk//NpfvPYjK2QscubFneiQYBU/7PLtTvVRmTA=";
    #       };

    #       cargoDeps = pkgs.rustPlatform.importCargoLock {
    #         lockFile = src + "/Cargo.lock";
    #         allowBuiltinFetchGit = true;
    #       };
    #     });
    #   })
    # ];
  };
}
