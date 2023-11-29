{
  host,
  isNixOS,
  lib,
  ...
}: {
  options.iynaix = {
    anime4k.enable = lib.mkEnableOption "anime4k" // {default = true;};
    deadbeef.enable = lib.mkEnableOption "deadbeef" // {default = host == "desktop";};
    helix.enable = lib.mkEnableOption "helix";
    kitty.enable = lib.mkEnableOption "kitty" // {default = isNixOS;};
    obs-studio.enable = lib.mkEnableOption "obs-studio" // {default = isNixOS && host == "desktop";};
    pathofbuilding.enable = lib.mkEnableOption "pathofbuilding" // {default = isNixOS;};
    rclip.enable = lib.mkEnableOption "rclip";
    trimage.enable = lib.mkEnableOption "trimage";
    vlc.enable = lib.mkEnableOption "vlc";
    wezterm.enable = lib.mkEnableOption "wezterm" // {default = isNixOS;};
    wallust = with lib.types; {
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
    };
  };
}
