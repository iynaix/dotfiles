{
  pkgs,
  user,
  ...
}: let
  # sets a random wallpaper and changes the colors
  hypr-wallpaper = pkgs.writeShellScriptBin "hypr-wallpaper" ''
    ${pkgs.python3}/bin/python3 ${../../programs/wallust/hypr-wallpaper.py} "$@"
  '';
  rofi-wallpaper = pkgs.writeShellScriptBin "rofi-wallpaper" ''
    hyprctl dispatch exec '[float;size 30%;center] imv -c "bind <Escape> quit" ~/Pictures/Wallpapers'
  '';
in {
  config = {
    home-manager.users.${user} = {
      home = {
        packages = [
          hypr-wallpaper
          rofi-wallpaper
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
