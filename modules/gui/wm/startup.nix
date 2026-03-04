{ lib, ... }:
{
  flake.modules.nixos.core = {
    options.custom = {
      startup = lib.mkOption {
        description = "Programs to run on startup";
        type = lib.types.listOf (
          lib.types.oneOf [
            lib.types.str
            (lib.types.submodule {
              options = {
                app-id = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  description = "The app-id (class) of the program to start";
                  default = null;
                };
                enable = lib.mkEnableOption "Rule" // {
                  default = true;
                };
                title = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  description = "The window title of the program to start, for differentiating between multiple instances";
                  default = null;
                };
                spawn = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  description = "Command to execute";
                  default = null;
                };
                workspace = lib.mkOption {
                  type = lib.types.nullOr lib.types.int;
                  description = "lib.Optional workspace to start program on";
                  default = null;
                };
                niriArgs = lib.mkOption {
                  type = lib.types.attrs;
                  description = "Extra arguments for niri window rules";
                  default = { };
                };
              };
            })
          ]
        );
        default = [ ];
      };

      startupServices = lib.mkOption {
        description = "Services to start after the WM is initialized";
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
    };

  };

  flake.modules.nixos.wm =
    # generic functionality for all WMs
    { config, pkgs, ... }:
    let
      inherit (config.custom.constants) host;
      # ensure setting terminal title using --title or exec with -e works
      termExe =
        assert config.custom.programs.terminal.package.pname == "ghostty";
        "ghostty";
    in
    {
      custom = {
        startup = [
          {
            app-id = "helium";
            spawn = [
              (lib.getExe (
                pkgs.writeShellApplication {
                  name = "init-helium";
                  runtimeInputs = [
                    pkgs.custom.helium
                    config.custom.programs.dotfiles-rs
                  ];
                  text = ''
                    helium --profile-directory=Default &
                    sleep 1; helium --incognito &
                    # no-op if not niri
                    sleep 5; niri-resize-workspace 1
                  '';
                }
              ))
            ];
            workspace = 1;
          }

          # file manager
          {
            app-id = "nemo";
            # NOTE: nemo seems ignore --class and --name flags?
            spawn = [ "nemo" ];
            workspace = 4;
          }

          # terminal
          # NOTE: use --class instead of --title to fix ghostty not properly setting initialTitle:
          # https://github.com/ghostty-org/ghostty/discussions/8804
          rec {
            app-id = "${config.custom.programs.terminal.app-id}-vertical";
            spawn = [
              termExe
              "--class=${app-id}"
            ];
            workspace = 7;
            niriArgs = {
              open-maximized = true;
            };
          }

          # librewolf for discord
          {
            app-id = "librewolf";
            spawn = [ "librewolf" ];
            workspace = 9;
            niriArgs = {
              open-maximized = true;
            };
          }

          # download related
          rec {
            enable = host == "desktop";
            app-id = "${config.custom.programs.terminal.app-id}-dl";
            spawn = [
              termExe
              "--class=${app-id}"
            ];
            workspace = 8;
          }
          rec {
            enable = host == "desktop";
            app-id = "${config.custom.programs.terminal.app-id}-yt.txt";
            spawn = [
              termExe
              "--class=${app-id}"
              "-e"
              "nvim"
              "${config.hj.directory}/Desktop/yt.txt"
            ];
            workspace = 8;
          }
          /*
            # fix gparted "cannot open display: :0" error
            {
              spawn = [
                (lib.getExe pkgs.xorg.xhost)
                "+local:${user}"
              ];
            }

            # fix Authorization required, but no authorization protocol specified error
            {
              spawn = [
                (lib.getExe pkgs.xorg.xhost)
                "si:localuser:root"
              ];
            }
          */
        ];
      };
    };
}
