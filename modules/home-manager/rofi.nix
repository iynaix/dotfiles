{ lib, ... }:
{
  options.custom = {
    rofi = {
      theme = lib.mkOption {
        type = lib.types.nullOr (
          lib.types.enum [
            "adapta"
            "arc"
            "black"
            "catppuccin"
            "cyberpunk"
            "dracula"
            "everforest"
            "gruvbox"
            "lovelace"
            "navy"
            "nord"
            "onedark"
            "paper"
            "solarized"
            "tokyonight"
            "yousai"
          ]
        );
        default = null;
        description = "Rofi launcher theme";
      };
      width = lib.mkOption {
        type = lib.types.int;
        default = 800;
        description = "Rofi launcher width";
      };
    };
  };
}
