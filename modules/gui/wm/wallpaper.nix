{ lib, ... }:
let
  inherit (lib) mkMerge;
in
{
  flake.nixosModules.wm =
    { pkgs, ... }:
    mkMerge [
      {
        environment = {
          systemPackages = with pkgs; [
            pkgs.custom.dotfiles-rs
            swww
            nomacs
          ];
        };

        custom.persist = {
          home = {
            directories = [
              ".cache/czkawka"
            ];
          };
        };
      }

      # rclip
      {
        environment = {
          systemPackages = [ pkgs.rclip ];

          shellAliases = {
            wallrg = "wallpaper search -t 50";
          };
        };

        custom.persist = {
          home = {
            directories = [
              ".cache/clip"
              ".cache/huggingface"
              ".config/Ultralytics"
            ];
            cache.directories = [ ".local/share/rclip" ];
          };
        };
      }
    ];
}
