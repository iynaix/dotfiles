{ lib, ... }:
{
  options.custom = {
    fonts = {
      regular = lib.mkOption {
        type = lib.types.str;
        default = "Geist Regular";
        description = "The font to use for regular text";
      };
      monospace = lib.mkOption {
        type = lib.types.str;
        default = "JetBrainsMono Nerd Font";
        description = "The font to use for monospace text";
      };
      packages = lib.mkOption {
        type = with lib.types; listOf package;
        description = "The packages to install for the fonts";
      };
    };
  };
}
