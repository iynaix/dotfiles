{lib, ...}: {
  options.iynaix = {
    rofi = {
      launcher = {
        style = lib.mkOption {
          type = lib.types.string;
          default = "1-1";
          description = "Rofi launcher style for given type, e.g. 1-1";
        };
        theme = lib.mkOption {
          type = lib.types.nullOr (lib.types.enum [
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
          ]);
          default = "catppuccin";
          description = "Rofi launcher theme";
        };
      };
      width = lib.mkOption {
        type = lib.types.int;
        default = 800;
        description = "Rofi launcher width";
      };
    };
  };
}
