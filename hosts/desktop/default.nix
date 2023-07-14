{
  config,
  pkgs,
  user,
  ...
}: let
  displayCfg = config.iynaix.displays;
  hyprlandCfg = config.iynaix.hyprland;
in {
  imports = [./hardware.nix];

  config = {
    iynaix = {
      # hardware
      am5.enable = true;
      hdds.enable = true;

      displays = {
        monitor1 = "DP-2";
        monitor2 =
          if hyprlandCfg.enable
          then "DP-4"
          else "DP-0.8";
        monitor3 =
          if hyprlandCfg.enable
          then "HDMI-A-1"
          else "HDMI-0";
      };

      # wayland settings
      hyprland = {
        enable = true;
        nvidia = true;
        monitors = ''
          monitor = ${displayCfg.monitor1}, 3440x1440@160,1440x1080,1
          monitor = ${displayCfg.monitor2}, 2560x1440,0x728,1,transform,1
          monitor = ${displayCfg.monitor3}, 1920x1080,1754x0,1
        '';
      };
      waybar = {
        style-template = ''
          /* add rounded corners for leftmost modules-right */
          #pulseaudio {
            border-radius: 12px 0 0 12px;
          }
        '';
      };
      wallpaper.transition = "grow";

      pathofbuilding.enable = true;
      smplayer.enable = true;
      torrenters.enable = true;
      virt-manager.enable = true;
    };

    networking.hostId = "89eaa833"; # required for zfs

    # environment.systemPackages = with pkgs; [ ];

    home-manager.users.${user} = {
      home = {
        packages = with pkgs; [
          deadbeef
          vlc
          ffmpeg
          # vial
        ];
      };

      programs.obs-studio.enable = true;
    };

    # required for vial to work
    # services.udev.extraRules = ''KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"'';

    iynaix.persist.home.directories = [
      ".config/smplayer"
    ];
  };
}
