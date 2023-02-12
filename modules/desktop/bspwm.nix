{ pkgs, host, ... }:
let
  window_gap = if host.hostName == "desktop" then 8 else 4;
  padding = if host.hostName == "desktop" then 8 else 4;
  bar_height = 30;
  border_width = 2;
  # colors
  normal = "#30302f";
  focused = "#4491ed";
  # window classes and desktops
  termclass = "Alacritty";
  chromeclass = "Brave-browser";
  webdesktop = "^1";
  filedesktop = "^3";
  nemodesktop = "^4";
  secondarytermdesktop = "^7";
  listdesktop = "^8";
  chatdesktop = "^9";
  dldesktop = "^10";
in {
  imports = [ ./dunst.nix ./polybar.nix ./sxhkd.nix ];

  xsession.windowManager.bspwm = {
    enable = true;
    settings = {
      automatic_scheme = "longest_side";

      # borders and gaps
      border_width = 2;
      active_border_color = normal;
      normal_border_color = normal;
      focused_border_color = focused;

      window_gap = window_gap;
      top_padding = padding + bar_height;
      left_padding = padding;
      right_padding = padding;
      bottom_padding = padding;

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
    # uses one shot rules for startup
    startupPrograms = [
      # web browsers
      ''bspc rule -a ${chromeclass} -o desktop="${webdesktop}"''
      "brave --profile-directory=Default"
      ''bspc rule -a ${chromeclass} -o desktop="${webdesktop}" follow=on''
      "brave --incognito"

      # nemo
      ''bspc rule -a Nemo:nemo -o desktop="${nemodesktop}"''
      "nemo"

      # terminals
      ''bspc rule -a ${termclass}:ranger -o desktop="${filedesktop}"''
      "$TERMINAL --class ${termclass},ranger -e ranger ~/Downloads"
      ''
        bspc rule -a ${termclass}:initialterm -o desktop="${secondarytermdesktop}" follow=on''
      "$TERMINAL --class ${termclass},initialterm"

      # chat
      "firefox-devedition --class=ffchat https://discordapp.com/channels/@me https://web.whatsapp.com http://localhost:9091"

      # download stuff
      ''bspc rule -a ${termclass}:dltxt -o desktop="${dldesktop}"''
      "$TERMINAL --class ${termclass},dltxt -e nvim ~/Desktop/yt.txt"
      ''bspc rule -a ${termclass}:dlterm -o desktop="${dldesktop}"''
      "$TERMINAL --class ${termclass},dlterm"

      # force polybar to start, see:
      # https://www.reddit.com/r/NixOS/comments/v8ikwq/polybar_doesnt_start_at_launch
      "systemctl --user restart polybar"

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
      picom
      polybar
      rofi
      rofi-power-menu
      sxiv
      xwallpaper
    ];

    file."Pictures/Wallpapers" = {
      source = ./wallpapers;
      recursive = true;
    };
  };
}
