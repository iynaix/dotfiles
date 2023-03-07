{ pkgs, host, user, lib, config, ... }:
let
  cfg = config.iynaix.hyprland;
  displayCfg = config.iynaix.displays;
  hyprBatch = cmds: ''hyprctl --batch "'' + (lib.concatStringsSep " ; " cmds) + ''"'';
  # sets master center
  # ultrawideStart = lib.optionalString (displayCfg.monitor1 == "DP-2") hyprBatch [
  #   "dispatch workspace 1"
  #   "dispatch layoutmsg orientationcenter"
  #   "dispatch workspace 2"
  #   "dispatch layoutmsg orientationcenter"
  #   "dispatch workspace 3"
  #   "dispatch layoutmsg orientationcenter"
  #   "dispatch workspace 4"
  #   "dispatch layoutmsg orientationcenter"
  #   "dispatch workspace 5"
  #   "dispatch layoutmsg orientationcenter"
  # ];
  ultrawideStart = "";
  # sets vertical splits
  verticalStart = lib.optionalString (displayCfg.monitor2 == "DP-4") hyprBatch [
    "dispatch workspace 6"
    "dispatch layoutmsg orientationtop"
    "dispatch workspace 7"
    "dispatch layoutmsg orientationtop"
    "dispatch workspace 8"
    "dispatch layoutmsg orientationtop"
  ];
  hyprStart = pkgs.writeShellScriptBin "hyprland-start" /* sh */ ''
    ${verticalStart}
    hyprctl dispatch workspace 7
    ${ultrawideStart}
    hyprctl dispatch workspace 1
  '';
  hyprStartCleanup = pkgs.writeShellScriptBin "hyprland-start-cleanup" /* sh */ ''
    ${lib.concatStringsSep "\n"  (["sleep 10"] ++ cfg.startupCleanup)}
  '';
in
{
  options.iynaix.hyprland = {
    startupPrograms = lib.mkOption {
      type = with lib.types;
        listOf str;
      default = [ ];
      description = "Programs to start on startup";
    };
  };
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
      iynaix.hyprland.startupPrograms =
        [
          # replace with exec once
          "exec-once = ${hyprStart}/bin/hyprland-start"

          "windowrule=workspace ${webdesktop} silent,brave-browser"
          "windowrule=workspace ${nemodesktop} silent,nemo"
          "windowrule=workspace ${secondarytermdesktop} silent,initialterm"
          "windowrule=workspace ${chatdesktop} silent,firefox-aurora"
          "windowrule=workspace ${dldesktop} silent,dltxt"
          "windowrule=workspace ${dldesktop} silent,dlterm"

          # browsers
          "exec-once = brave --profile-directory=Default"
          "exec-once = brave --incognito"

          # file manager
          "exec-once = nemo"

          # terminal
          "exec-once = $TERMINAL --class initialterm"

          # firefox
          "exec-once = firefox-devedition https://discordapp.com/channels/@me https://web.whatsapp.com http://localhost:9091"

          "exec-once = $TERMINAL --class dltxt -e nvim ~/Desktop/yt.txt"
          "exec-once = $TERMINAL --class dlterm"

          # cleanup bindings after startup
          "exec = ${hyprStartCleanup}/bin/hyprland-start-cleanup"
        ];
      iynaix.hyprland.startupCleanup = [
        ''hyprctl keyword windowrule "workspace unset,brave-browser"''
        ''hyprctl keyword windowrule "workspace unset,nemo"''
        ''hyprctl keyword windowrule "workspace unset,inititalterm"''
        ''hyprctl keyword windowrule "workspace unset,firefox-aurora"''
        ''hyprctl keyword windowrule "workspace unset,dltxt"''
        ''hyprctl keyword windowrule "workspace unset,dlterm"''
      ];
    }
  );
}
