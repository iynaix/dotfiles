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
in
{
  options.iynaix.hyprland = {
    startupPrograms = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
      description = "Programs to start on startup";
    };
  };

  config = lib.mkIf cfg.enable {
    iynaix.hyprland.startupPrograms =
      let
        # window classes and desktops
        termclass = "Alacritty";
        browserclass = "Brave-browser";
        webdesktop = "1";
        # filedesktop = "3";
        nemodesktop = "4";
        secondarytermdesktop = "7";
        # listdesktop = "8";
        chatdesktop = "9";
        dldesktop = "10";
      in
      [
        # replace with exec once
        "# ${hyprStart}/bin/hyprland-start"
        "exec = ${hyprStart}/bin/hyprland-start"

        # "windowrule=workspace 1 silent,brave"
        # "windowrule=workspace 1 silent,brave --incognito"
        # "windowrule=workspace 4 silent,nemo"
        # "windowrule=workspace 7 silent,$TERMINAL:initialterm"
        # "windowrule=workspace 9 silent,firefox-devedition --class=ffchat https://discordapp.com/channels/@me https://web.whatsapp.com http://localhost:9091"
        # "windowrule=workspace 0 silent,$TERMINAL --class ${termclass},dltxt -e nvim ~/Desktop/yt.txt"
        # "windowrule=workspace 0 silent,$TERMINAL --class ${termclass},dlterm"

        # ''bspc rule -a ${termclass}:dlterm -o desktop=${dldesktop}''
        # "$TERMINAL --class ${termclass},dlterm"

        # ''bspc rule -a ${browserclass} -o desktop=${webdesktop}''
        # "brave --profile-directory=Default"
        # ''bspc rule -a ${browserclass} -o desktop=${webdesktop} follow=on''
        # "brave --incognito"

        # # nemo
        # ''bspc rule -a Nemo:nemo -o desktop=${nemodesktop}''
        # "nemo"

        # # terminals
        # # ''bspc rule -a ${termclass}:ranger -o desktop=${filedesktop}''
        # # "$TERMINAL --class ${termclass},ranger -e ranger ~/Downloads"
        # ''
        #   bspc rule -a ${termclass}:initialterm -o desktop=${secondarytermdesktop} follow=on''
        # "$TERMINAL --class ${termclass},initialterm"

        # # chat
        # "firefox-devedition --class=ffchat https://discordapp.com/channels/@me https://web.whatsapp.com http://localhost:9091"

        # # download stuff
        # ''bspc rule -a ${termclass}:dltxt -o desktop=${dldesktop}''
        # "$TERMINAL --class ${termclass},dltxt -e nvim ~/Desktop/yt.txt"
        # ''bspc rule -a ${termclass}:dlterm -o desktop=${dldesktop}''
        # "$TERMINAL --class ${termclass},dlterm"
      ];
  };
}
