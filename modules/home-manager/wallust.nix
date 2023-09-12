{
  lib,
  config,
  ...
}: let
  cfg = config.iynaix.wallust;
in {
  options.iynaix.wallust = with lib.types; {
    enable = lib.mkEnableOption "wallust" // {default = true;};
    threshold = lib.mkOption {
      type = int;
      default = 20;
    };

    entries = lib.mkOption {
      type = attrsOf (submodule {
        options = {
          enable = lib.mkOption {
            type = bool;
            default = false;
            description = "Enable this entry";
          };
          text = lib.mkOption {
            type = str;
            description = "Content of the template file";
          };
          target = lib.mkOption {
            type = str;
            description = "Absolute path to the file to write the template (after templating), e.g. ~/.config/dunst/dunstrc";
          };
          onChange = lib.mkOption {
            type = str;
            description = "Shell commands to run when file has changed between generations. The script will be run after the new files have been linked into place.";
            default = "";
          };
        };
      });
      default = [];
      description = ''
        Example entries, which are just a file you wish to apply `wallust` generated colors to.
        template = "dunstrc"
      '';
    };

    # enable wallust for individual programs
    cava = lib.mkEnableOption "cava" // {default = cfg.enable;};
    dunst = lib.mkEnableOption "dunst" // {default = cfg.enable;};
    gtk = lib.mkEnableOption "gtk";
    rofi = lib.mkEnableOption "rofi" // {default = cfg.enable;};
    shell = lib.mkEnableOption "shell" // {default = cfg.enable;};
    swaylock = lib.mkEnableOption "swaylock" // {default = cfg.enable;};
    waybar = lib.mkEnableOption "waybar" // {default = cfg.enable;};
    wezterm = lib.mkEnableOption "wezterm" // {default = cfg.enable;};
    zathura = lib.mkEnableOption "zathura" // {default = cfg.enable;};
  };
}
