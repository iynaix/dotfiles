{
  pkgs,
  lib,
  isNixOS,
  ...
}: {
  iynaix = {
    displays = [
      {
        name = "DP-2";
        hyprland = "3440x1440@144,1440x1080,1";
        workspaces = [1 2 3 4 5];
      }
      {
        name = "DP-4";
        hyprland = "2560x1440,0x728,1,transform,1";
        workspaces = [6 7 8];
      }
      {
        name = "HDMI-A-1";
        hyprland = "1920x1080,1754x0,1";
        workspaces = [9 10];
      }
    ];

    deadbeef.enable = true;
    ghostty.enable = true;
    hyprland.plugin = "hyprnstack";
    obs-studio.enable = true;
    pathofbuilding.enable = true;
    rclip.enable = true;
    vlc.enable = true;
    # wallust.colorscheme = "tokyo-night";
    # waybar.persistent-workspaces = true;
  };

  home = {
    packages = lib.mkIf isNixOS (
      with pkgs; [
        ffmpeg
        # vial
      ]
    );
  };

  # required for vial to work?
  # services.udev.extraRules = ''KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"'';
}
