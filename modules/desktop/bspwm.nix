{ pkgs, host, user, lib, config, ... }:
let
  cfg = config.iynaix.bspwm;
  # misc bspwm variables here
  barHeight = 30;
  # border_width = 2;
  # colors
  normal = "#30302f";
  focused = "#4491ed";
  # window classes and desktops
  termclass = "Alacritty";
  chromeclass = "Brave-browser";
  webdesktop = "1";
  # filedesktop = "3";
  nemodesktop = "4";
  secondarytermdesktop = "7";
  # listdesktop = "8";
  chatdesktop = "9";
  dldesktop = "10";
in
{
  imports = [
    ./dunst.nix
    ./picom.nix
    ./polybar.nix
    ./rofi.nix
    ./sxhkd.nix
  ];

  options.iynaix.bspwm = {
    enable = lib.mkEnableOption "bspwm";
    windowGap = lib.mkOption {
      type = lib.types.int;
      default = 4;
      description = "Size of the gap that separates windows";
    };
    padding = lib.mkOption {
      type = lib.types.int;
      default = 4;
      description = "Padding space added at the sides of the monitor or desktop";
    };
  };

  config = lib.mkIf cfg.enable {
    services.xserver = {
      enable = true;
      windowManager.bspwm.enable = true;
    };

    home-manager.users.${user} = {
      xsession.enable = true;
      xsession.windowManager.bspwm = {
        enable = cfg.enable;
        settings = {
          automatic_scheme = "longest_side";

          # borders and gaps
          border_width = 2;
          active_border_color = normal;
          normal_border_color = normal;
          focused_border_color = focused;

          window_gap = cfg.windowGap;
          top_padding = cfg.padding + barHeight;
          left_padding = cfg.padding;
          right_padding = cfg.padding;
          bottom_padding = cfg.padding;

          presel_feedback_color = focused;
          split_ratio = 0.5;
          focus_follows_pointer = true;
          pointer_follows_monitor = true;

          # smart gaps
          single_monocle = true;
          borderless_monocle = false;
          gapless_monocle = true;
          top_monocle_padding = 0;
          right_monocle_padding = 0;
          bottom_monocle_padding = 0;
          left_monocle_padding = 0;

          # handle the mouse
          pointer_modifier = "mod4";
          pointer_action1 = "move";
          pointer_action2 = "resize_corner";
          pointer_motion_interval = "7ms";

          # handle unplugging monitors
          remove_disabled_monitors = false;
          remove_unplugged_monitors = false;

          # custom external rules
          external_rules_command = "~/bin/bspwm_external_rules";
        };
        rules = {
          "ffchat" = { desktop = chatdesktop; };
          "Transmission-gtk" = { desktop = dldesktop; };
          "Zathura" = { state = "tiled"; };
        };
        extraConfigEarly = lib.concatStringsSep "\n" [
          # fix the cursor
          "xsetroot -cursor_name left_ptr"
        ];
        # restart polybar after bspwm has initialized
        # https://www.reddit.com/r/NixOS/comments/v8ikwq/polybar_doesnt_start_at_launch
        extraConfig = lib.mkAfter "systemctl --user restart polybar";

        # uses one shot rules for startup
        startupPrograms = [
          # web browsers
          ''bspc rule -a ${chromeclass} -o desktop=${webdesktop}''
          "brave --profile-directory=Default"
          ''bspc rule -a ${chromeclass} -o desktop=${webdesktop} follow=on''
          "brave --incognito"

          # nemo
          ''bspc rule -a Nemo:nemo -o desktop=${nemodesktop}''
          "nemo"

          # terminals
          # ''bspc rule -a ${termclass}:ranger -o desktop=${filedesktop}''
          # "$TERMINAL --class ${termclass},ranger -e ranger ~/Downloads"
          ''
            bspc rule -a ${termclass}:initialterm -o desktop=${secondarytermdesktop} follow=on''
          "$TERMINAL --class ${termclass},initialterm"

          # chat
          "firefox-devedition --class=ffchat https://discordapp.com/channels/@me https://web.whatsapp.com http://localhost:9091"

          # download stuff
          ''bspc rule -a ${termclass}:dltxt -o desktop=${dldesktop}''
          "$TERMINAL --class ${termclass},dltxt -e nvim ~/Desktop/yt.txt"
          ''bspc rule -a ${termclass}:dlterm -o desktop=${dldesktop}''
          "$TERMINAL --class ${termclass},dlterm"

          # must be the last line in the file
          "bspc subscribe all | bspc-events"
        ];
      };

      services.clipmenu = {
        enable = true;
        launcher = "rofi";
      };

      home = {
        packages = with pkgs; [
          maim
          sxiv
          xwallpaper
        ];

        file.".config/sxiv/exec/key-handler".text = ''
          #!/usr/bin/env sh

          while read file
          do
              case "$1" in
              "C-c")
                  xclip -selection clipboard "$file" -t image/png ;;
              "C-d")
                  mv -f "$file" /tmp ;;
              esac
          done
        '';
      };

      # shell aliases that require bspwm
      programs.zsh.shellAliases = {
        ":sp" = "bspc node -p south; $TERMINAL & disown";
        ":vs" = "bspc node -p east; $TERMINAL & disown";
      };
    };
  };
}
