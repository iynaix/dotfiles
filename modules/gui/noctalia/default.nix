{ inputs, lib, ... }:
{
  flake.nixosModules.wm =
    let
      inherit (lib) getExe mkBefore;
      noctaliaSettings = import ./_settings.nix;
    in
    { pkgs, ... }:
    {
      # don't use the systemd service, it's very buggy :(
      nixpkgs.overlays = [
        (_: _prev: {
          noctalia-shell = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs {
            patches = [ ./face-aware-crop.patch ];
          };
        })
      ];

      environment.systemPackages = [
        pkgs.noctalia-shell
      ];

      hj.xdg.config.files = {
        "noctalia/settings.json".text = lib.strings.toJSON noctaliaSettings;
      };

      custom.shell.packages = {
        noctalia-shell-reload = {
          runtimeInputs = with pkgs; [
            killall
            noctalia-shell
          ];
          text = /* sh */ ''
            killall .quickshell-wrapper && noctalia-shell
          '';
        };
      };

      custom.startup = mkBefore [
        {
          spawn = [
            # set random wallpaper on startup
            (getExe (
              pkgs.writeShellApplication {
                name = "noctalia-startup";
                runtimeInputs = with pkgs; [
                  noctalia-shell
                  custom.dotfiles-rs
                ];
                text = /* sh */ ''
                  noctalia-shell &
                  sleep 1
                  wallpaper
                '';
              }
            ))
          ];
        }
      ];

      custom.persist = {
        home = {
          directories = [
            ".config/noctalia"
          ];

          # mainly so the new version popup doesn't reappear
          cache.directories = [
            ".cache/noctalia"
          ];
        };
      };
    };
}
