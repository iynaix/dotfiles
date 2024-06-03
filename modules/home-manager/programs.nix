{
  isNixOS,
  lib,
  pkgs,
  ...
}:
{
  options.custom = {
    deadbeef.enable = lib.mkEnableOption "deadbeef";
    ghostty = {
      enable = lib.mkEnableOption "ghostty";
      config = lib.mkOption {
        type = with lib.types; attrsOf anything;
        default = { };
        description = "Extra ghostty configuration.";
      };
    };
    helix.enable = lib.mkEnableOption "helix";
    kitty.enable = lib.mkEnableOption "kitty" // {
      default = isNixOS;
    };
    mpv-anime.enable = lib.mkEnableOption "mpv-anime" // {
      default = true;
    };
    obs-studio.enable = lib.mkEnableOption "obs-studio";
    pathofbuilding.enable = lib.mkEnableOption "pathofbuilding" // {
      default = isNixOS;
    };
    rclip.enable = lib.mkEnableOption "rclip";
    vlc.enable = lib.mkEnableOption "vlc";
    wallpaper-utils.enable = lib.mkEnableOption "wallpaper-utils";
    wallust = with lib.types; {
      enable = lib.mkEnableOption "wallust" // {
        default = true;
      };
      colorscheme = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        description = "The colorscheme to use. If null, will use the default colorscheme from the wallpaper.";
      };
      nixJson = lib.mkOption {
        type = lib.types.submodule { freeformType = (pkgs.formats.json { }).type; };
        default = { };
        description = "Data to be written to nix.json for use in other programs at runtime.";
      };
      templates = lib.mkOption {
        type = attrsOf (submodule {
          options = {
            text = lib.mkOption {
              type = str;
              description = "Content of the template file";
            };
            target = lib.mkOption {
              type = str;
              description = "Absolute path to the file to write the template (after templating), e.g. ~/.config/dunst/dunstrc";
            };
          };
        });
        default = [ ];
        description = ''
          Example templates, which are just a file you wish to apply `wallust` generated colors to.
          template = "dunstrc"
        '';
      };
    };
  };
}
