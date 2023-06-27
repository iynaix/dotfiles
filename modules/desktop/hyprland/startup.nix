{
  pkgs,
  host,
  user,
  lib,
  config,
  ...
}: let
  cfg = config.iynaix.hyprland;
  displays = config.iynaix.displays;
  hyprCleanup =
    pkgs.writeShellScriptBin "hypr-cleanup"
    /*
    sh
    */
    ''
      ${lib.concatStringsSep "\n" ([
          "sleep ${
            if host == "laptop"
            then "20"
            else "10"
          }"
        ]
        ++ cfg.startupCleanup)}
    '';
  hyprResetMonitors =
    pkgs.writeShellScriptBin "hypr-reset-monitors"
    /*
    sh
    */
    ''
      hyprctl dispatch moveworkspacetomonitor 1 ${displays.monitor1}
      hyprctl dispatch moveworkspacetomonitor 2 ${displays.monitor1}
      hyprctl dispatch moveworkspacetomonitor 3 ${displays.monitor1}
      hyprctl dispatch moveworkspacetomonitor 4 ${displays.monitor1}
      hyprctl dispatch moveworkspacetomonitor 5 ${displays.monitor1}
      hyprctl dispatch moveworkspacetomonitor 6 ${displays.monitor2}
      hyprctl dispatch moveworkspacetomonitor 7 ${displays.monitor2}
      hyprctl dispatch moveworkspacetomonitor 8 ${displays.monitor2}
      hyprctl dispatch moveworkspacetomonitor 9 ${displays.monitor3}
      hyprctl dispatch moveworkspacetomonitor 10 ${displays.monitor3}

      hyprctl dispatch workspace 9
      hyprctl dispatch workspace 7

      hyprctl dispatch focusmonitor ${displays.monitor1}

      # set wallpapers again
      hypr-reset

      # reset waybar
      launch-waybar
    '';
in {
  options.iynaix.hyprland = {
    startupCleanup = lib.mkOption {
      type = with lib.types; listOf str;
      default = [];
      description = "Programs to start on startup";
    };
  };

  config = lib.mkIf cfg.enable (
    let
      # window classes and desktops
      webdesktop = "1";
      nemodesktop = "4";
      secondarytermdesktop = "7";
      chatdesktop = "9";
      dldesktop = "10";
    in {
      home-manager.users.${user} = {
        home.packages = [hyprResetMonitors];

        # start hyprland
        programs.zsh = let
          hyprlandInit = ''
            if [ "$(tty)" = "/dev/tty1" ]; then
              exec Hyprland &> /dev/null
            fi
          '';
        in {
          loginExtra = hyprlandInit;
          profileExtra = hyprlandInit;
        };

        xdg.configFile."hypr/ipc.py".source = ./ipc.py;
      };

      iynaix.hyprland.extraBinds = {
        exec-once = [
          # init ipc listener
          "${pkgs.socat}/bin/socat - UNIX-CONNECT:/tmp/hypr/$(echo $HYPRLAND_INSTANCE_SIGNATURE)/.socket2.sock | ${pkgs.python3}/bin/python ~/.config/hypr/ipc.py &"

          # browsers
          "brave --profile-directory=Default"
          "brave --incognito"

          # file manager
          "nemo"

          # terminal
          "$TERMINAL --class initialterm"

          # firefox
          "firefox-devedition https://discordapp.com/channels/@me https://web.whatsapp.com http://localhost:9091"

          "$TERMINAL --class dltxt -e nvim ~/Desktop/yt.txt"
          "$TERMINAL --class dlterm"

          "${pkgs.swayidle}/bin/swayidle -w timeout 480 'hyprctl dispatch dpms off' resume 'hyprctl dispatch dpms on'"

          # focus the initial workspaces on startup
          "hyprctl dispatch workspace 9"
          "hyprctl dispatch workspace 7"
          "hyprctl dispatch workspace 1"

          "hypr-wallpaper"
        ];
        exec = [
          "${hyprCleanup}/bin/hypr-cleanup"
        ];
        windowrule = [
          "workspace ${webdesktop} silent,Brave-browser"
          "workspace ${nemodesktop} silent,nemo"
          "workspace ${secondarytermdesktop} silent,initialterm"
          "workspace ${chatdesktop} silent,firefox-aurora"
          "workspace ${dldesktop} silent,dltxt"
          "workspace ${dldesktop} silent,dlterm"
        ];
      };

      iynaix.hyprland.startupCleanup = [
        ''hyprctl keyword windowrule "workspace unset,Brave-browser"''
        ''hyprctl keyword windowrule "workspace unset,nemo"''
        ''hyprctl keyword windowrule "workspace unset,firefox-aurora"''
      ];
    }
  );
}
