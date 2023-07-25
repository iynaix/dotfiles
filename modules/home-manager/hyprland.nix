{
  lib,
  config,
  ...
}: {
  options.iynaix = {
    hyprland = {
      enable = lib.mkEnableOption "Hyprland" // {default = true;};
      nvidia = lib.mkEnableOption "Nvidia";
      keybinds = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        description = ''
          Keybinds for Hyprland, see
          https://wiki.hyprland.org/Configuring/Binds/
        '';
        example = ''{ "SUPER, Return" = "exec, kitty"; }'';
        default = {};
      };
      monitors = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = ''
          Config for monitors, see
          https://wiki.hyprland.org/Configuring/Monitors/
        '';
      };
    };

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

    waybar = {
      enable = lib.mkEnableOption "waybar" // {default = config.iynaix.hyprland.enable;};
      config = lib.mkOption {
        type = lib.types.attrs;
        default = {};
        description = "Additional waybar config (wallust templating can be used)";
      };
      css = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Additional waybar css (wallust templating can be used)";
      };
      border-radius = lib.mkOption {
        type = lib.types.str;
        default = "12px";
        description = "Border-radius for waybar";
      };
    };
  };
}
