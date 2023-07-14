{
  pkgs,
  user,
  lib,
  ...
}: let
  # sets a random wallpaper and changes the colors
  hypr-wallpaper = pkgs.writeShellScriptBin "hypr-wallpaper" ''
    ${pkgs.python3}/bin/python3 ${../../programs/wallust/hypr-wallpaper.py}
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
