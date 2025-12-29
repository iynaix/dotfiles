{ inputs, lib, ... }:
{
  flake.nixosModules.core = {
    options.custom = {
      programs.noctalia = {
        systemd.enable = lib.mkEnableOption "Start noctalia using systemd";
      };
    };
  };

  flake.nixosModules.wm =
    {
      config,
      isLaptop,
      pkgs,
      ...
    }:
    let
      inherit (lib)
        getExe
        mkIf
        mkBefore
        mkMerge
        ;
      noctaliaSettings = import ./_settings.nix { inherit lib isLaptop; };
      noctalia-shell' =
        inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs
          {
            patches = [ ./face-aware-crop.patch ];
          };
    in
    mkMerge [
      {
        # don't use the systemd service, it's very buggy :(
        nixpkgs.overlays = [
          (_: _prev: {
            noctalia-shell = noctalia-shell';
          })
        ];

        hj.xdg.config.files = {
          "noctalia/settings.json".text = lib.strings.toJSON noctaliaSettings;
        };

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
      }

      # start using the systemd service
      (mkIf config.custom.programs.noctalia.systemd.enable {
        services.noctalia-shell = {
          enable = true;
          package = noctalia-shell';
        };

        custom.shell.packages = {
          noctalia-shell-reload = {
            text = /* sh */ ''
              systemctl --user restart noctalia-shell
            '';
          };
        };
      })

      # start using WM startup
      (mkIf (!config.custom.programs.noctalia.systemd.enable) {
        environment.systemPackages = [
          noctalia-shell'
        ];

        custom.shell.packages = {
          noctalia-shell-reload = {
            runtimeInputs = with pkgs; [
              killall
              noctalia-shell
            ];
            text = /* sh */ ''
              killall .quickshell-wrapper || noctalia-shell &
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
      })
    ];
}
