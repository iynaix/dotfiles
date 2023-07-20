{
  pkgs,
  config,
  ...
}: let
  displayCfg = config.iynaix.displays;
in {
  iynaix = {
    displays = {
      monitor1 = "DP-2";
      monitor2 = "DP-4";
      monitor3 = "HDMI-A-1";
    };

    # wayland settings
    hyprland = {
      enable = true;
      monitors = ''
        monitor = ${displayCfg.monitor1}, 3440x1440@160,1440x1080,1
        monitor = ${displayCfg.monitor2}, 2560x1440,0x728,1,transform,1
        monitor = ${displayCfg.monitor3}, 1920x1080,1754x0,1
      '';
    };
    waybar = {
      css = ''
        /* add rounded corners for leftmost modules-right */
        #pulseaudio {
          border-radius: 12px 0 0 12px;
        }
      '';
    };

    pathofbuilding.enable = true;
    smplayer.enable = true;
  };

  home = {
    packages = with pkgs; [
      deadbeef
      vlc
      ffmpeg
      # vial
    ];
  };

  programs.obs-studio.enable = true;

  # required for vial to work?
  # services.udev.extraRules = ''KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"'';
}
