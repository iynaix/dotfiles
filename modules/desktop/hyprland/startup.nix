{ pkgs, host, user, lib, config, ... }:
let
  cfg = config.iynaix.hyprland;
  hyprSwitchWorkspace = pkgs.writeShellScriptBin "hypr-switch-ws" /* sh */ ''
    hyprctl dispatch workspace 9
    hyprctl dispatch workspace 7
    hyprctl dispatch workspace 1
  '';
  hyprCleanup = pkgs.writeShellScriptBin "hypr-cleanup" /* sh */ ''
    ${lib.concatStringsSep "\n"  (["sleep 10"] ++ cfg.startupCleanup)}
  '';
in
{
  options.iynaix.hyprland = {
    startupCleanup = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
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
    in
    {
      iynaix.hyprland.extraBinds = lib.mkAfter
        {
          exec-once = [
            "${hyprSwitchWorkspace}/bin/hypr-switch-ws"

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
