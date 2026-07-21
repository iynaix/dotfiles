{ lib, ... }:
{
  flake.modules.nixos.core = {
    options.custom.wm = {
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
                  type = lib.types.str;
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
                hyprlandArgs = lib.mkOption {
                  type = lib.types.attrs;
                  description = "Extra arguments for hyprland window rules";
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
      helium-chat = pkgs.writeShellApplication {
        name = "helium-chat";
        runtimeInputs = [ pkgs.custom.helium ];
        # specify xdg-data-dir directly to force launch a separate instance, if not it just reuses the "Default" session
        text = /* sh */ ''
          helium --profile-directory=Chat --xdg-data-dir=${config.hj.xdg.cache.directory}/net.imput.helium/Chat
        '';
      };
      # ensure setting terminal title using --title or exec with -e works
      termExe = "kitty";
    in
    {
      programs.uwsm.enable = true;

      # add desktop entry for helium-chat as well
      environment.systemPackages = [
        helium-chat
        (pkgs.makeDesktopItem {
          name = "Helium (Chat)";
          desktopName = "Helium (Chat)";
          genericName = "Web Browser";
          icon = "internet-chat";
          exec = lib.getExe helium-chat;
        })
      ];

      custom = {
        wm.startup = [
          {
            app-id = "helium";
            spawn = "uwsm app -- helium --profile-directory=Default";
            workspace = 1;
          }

          {
            app-id = "helium";
            spawn = "uwsm app -- helium --profile-directory=Default --incognito";
            workspace = 1;
          }

          # emacs
          {
            app-id = "emacs";
            spawn = "uwsm app -- emacsclient -c";
            workspace = 2;
            niriArgs = {
              open-maximized = true;
            };
          }

          # file manager
          {
            app-id = "nemo";
            # NOTE: nemo seems ignore --class and --name flags?
            spawn = "nemo";
            workspace = 4;
          }

          # terminal
          rec {
            app-id = "${config.custom.programs.terminal.app-id}-vertical";
            spawn = "uwsm app -- ${termExe} --class=${app-id}";
            workspace = 7;
            niriArgs = {
              open-maximized = true;
            };
          }

          # discord and other chats
          # does not currently work on niri, using raw regexes fixes it
          # https://github.com/BirdeeHub/nix-wrapper-modules/pull/581
          rec {
            app-id = "helium";
            title = ".*(Discord|WhatsApp|Flood).*";
            spawn = "uwsm app -- helium-chat";
            workspace = 9;
            niriArgs = {
              open-maximized = true;
            };
            hyprlandArgs = {
              initial_title = title;
            };
          }

          # download related
          rec {
            enable = host == "desktop";
            app-id = "${config.custom.programs.terminal.app-id}-dl";
            spawn = "uwsm app -- ${termExe} --class=${app-id}";
            workspace = 8;
          }
          rec {
            enable = host == "desktop";
            app-id = "${config.custom.programs.terminal.app-id}-yt.txt";
            spawn = "uwsm app -- ${termExe} --class=${app-id} -e nvim ${config.hj.directory}/Desktop/yt.txt";
            workspace = 8;
          }
        ];
      };
    };
}
