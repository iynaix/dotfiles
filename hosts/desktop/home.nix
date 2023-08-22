{
  pkgs,
  config,
  lib,
  isNixOS,
  ...
}: let
  cfg = config.iynaix;
  displayCfg = config.iynaix.displays;
in {
  iynaix = {
    displays = {
      monitor1 = "DP-2";
      monitor2 = "DP-4";
      monitor3 = "HDMI-A-1";
    };

    # shell.package = pkgs.bash;

    # wayland settings
    hyprland = {
      enable = true;
      nvidia = true;
      monitors = [
        "${displayCfg.monitor1}, 3440x1440@160,1440x1080,1"
        "${displayCfg.monitor2}, 2560x1440,0x728,1,transform,1"
        "${displayCfg.monitor3}, 1920x1080,1754x0,1"
      ];
    };
    waybar = {
      css = let
        radius = config.iynaix.waybar.border-radius;
      in ''
        /* add rounded corners for leftmost modules-right */
        #pulseaudio {
          border-radius: ${radius} 0 0 ${radius};
        }
      '';
    };

    wallust.gtk = false;
    pathofbuilding.enable = true;
    trimage.enable = false;
    vlc.enable = true;
  };

  home = {
    packages = lib.mkIf isNixOS (
      with pkgs;
        [
          deadbeef
          ffmpeg
          # vial
        ]
        ++ (lib.optional cfg.trimage.enable pkgs-iynaix.trimage)
    );
  };

  programs.obs-studio.enable = isNixOS;

  # required for vial to work?
  # services.udev.extraRules = ''KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"'';
}
