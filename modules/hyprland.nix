{lib, ...}: {
  options.iynaix.hyprland = {
    enable = lib.mkEnableOption "Hyprland" // {default = true;};
    nvidia = lib.mkEnableOption "Nvidia";
    keybinds = lib.mkOption {
      type = with lib.types; attrsOf str;
      description = ''
        Keybinds for Hyprland, see
        https://wiki.hyprland.org/Configuring/Binds/
      '';
      example = ''{ "SUPER, Return" = "exec, kitty"; }'';
      default = {};
    };
    monitors = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        Config for monitors, see
        https://wiki.hyprland.org/Configuring/Monitors/
      '';
    };
    extraVariables = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Extra variable config for Hyprland";
    };
    extraBinds = lib.mkOption {
      type = with lib.types; attrsOf unspecified;
      default = {};
      description = "Extra binds for Hyprland";
    };
  };
}
