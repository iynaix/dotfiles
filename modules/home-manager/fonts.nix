{ lib, pkgs, ... }:
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
        type = lib.types.listOf lib.types.package;
        default = with pkgs; [
          noto-fonts
          noto-fonts-cjk
          noto-fonts-emoji
          (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
        ];
        description = "The packages to install for the fonts";
      };
    };
  };
}
