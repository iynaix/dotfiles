{ lib, pkgs, ... }:
let
  inherit (lib) mkOption types;
  inherit (types) listOf package str;
in
{
  options.custom = {
    fonts = {
      regular = mkOption {
        type = str;
        default = "Geist";
        description = "The font to use for regular text";
      };
      monospace = mkOption {
        type = str;
        default = "JetBrainsMono Nerd Font";
        description = "The font to use for monospace text";
      };
      packages = mkOption {
        type = listOf package;
        description = "The packages to install for the fonts";
      };
    };
  };

  config = {
    # setup fonts for other distros, run "fc-cache -f" to refresh fonts
    fonts.fontconfig.enable = true;

    fonts = {
      enableDefaultPackages = true;

      packages = with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-emoji
        nerd-fonts.jetbrains-mono
      ];
    };
  };
}
