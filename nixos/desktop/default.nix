{
  user,
  lib,
  config,
  ...
}: {
  imports = [
    # WMs are mutually exclusive via a config options
    ./dunst.nix
    ./gnome3.nix
    ./gtk.nix
    ./hyprland
    ./kmonad.nix
  ];

  options.iynaix = {
    displays = {
      monitor1 = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "The name of the primary display, e.g. eDP-1";
      };
      monitor2 = lib.mkOption {
        type = lib.types.str;
        default = config.iynaix.displays.monitor1;
        description = "The name of the secondary display, e.g. eDP-1";
      };
      monitor3 = lib.mkOption {
        type = lib.types.str;
        default = config.iynaix.displays.monitor1;
        description = "The name of the tertiary display, e.g. eDP-1";
      };
    };
  };

  config = {
    home-manager.users.${user} = {
      home = {
        # copy wallpapers
        file."Pictures/Wallpapers" = {
          source = ./wallpapers;
          recursive = true;
        };
      };
    };
  };
}
