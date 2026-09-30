{
  tags = [ "wm" ];

  config =
    {
      config,
      host,
      lib,
      pkgs,
      ...
    }:
    let
      helium-chat = pkgs.writeShellApplication {
        name = "helium-chat";
        runtimeInputs = [ pkgs.custom.helium ];
        # specify xdg-data-dir directly to force launch a separate instance, if not it just reuses the "Default" session
        text = /* sh */ ''
          helium --profile-directory=Chat --xdg-data-dir=${config.hj.xdg.cache.directory}/net.imput.helium/Chat
        '';
      };
      startup = [
        {
          match.app_id = "helium";
          spawn = "helium --profile-directory=Default";
          workspace = 1;
        }

        {
          match.app_id = "helium";
          spawn = "helium --profile-directory=Default --incognito";
          workspace = 1;
        }

        # emacs
        {
          match.app_id = "emacs";
          spawn = "emacsclient -c";
          workspace = 2;
        }

        # file manager
        {
          match.app_id = "nemo";
          # NOTE: nemo seems ignore --class and --name flags?
          spawn = "nemo";
          workspace = 4;
        }

        # terminal
        rec {
          match.app_id = "${config.custom.programs.terminal.app_id}-vertical";
          spawn = "kitty --class=${match.app_id}";
          workspace = 7;
        }

        # discord and other chats
        {
          match = {
            app_id = "helium";
            title = ".*(Discord|WhatsApp|Flood).*";
          };
          spawn = "helium-chat";
          workspace = 9;
        }

        # download related
        (lib.optionalAttrs (host == "desktop") rec {
          match.app_id = "${config.custom.programs.terminal.app_id}-dl";
          spawn = "kitty --class=${match.app_id}";
          workspace = 8;
        })
        (lib.optionalAttrs (host == "desktop") rec {
          match.app_id = "${config.custom.programs.terminal.app_id}-yt.txt";
          spawn = "kitty --class=${match.app_id} -e nvim ${config.hj.directory}/Desktop/yt.txt";
          workspace = 8;
        })
      ];
    in
    {
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

      custom.programs = {
        umbriel.settings = lib.mkMerge (
          (
            startup
            |> lib.filter (s: s != { })
            |> map (s: {
              general.autostart = [ s.spawn ];
              window_rule = [
                {
                  match = s.match // {
                    at_startup = true;
                  };
                  default_workspace = toString s.workspace;
                }
              ];
            })
          )
          ++ [
            {
              # focus default workspace for each monitor
              general.autostart =
                config.custom.hardware.monitors
                |> lib.reverseList
                |> map (mon: ''umbriel msg workspace-switch:"${toString mon.defaultWorkspace}"'');
            }
          ]
        );
      };
    };
}
