{
  flake.nixosModules.core =
    { lib, pkgs, ... }:
    let
      inherit (lib) mkOption;
    in
    {
      options.custom = {
        fonts = {
          regular = mkOption {
            type = lib.types.str;
            default = "Geist";
            description = "The font to use for regular text";
          };
          monospace = mkOption {
            type = lib.types.str;
            default = "JetBrainsMono Nerd Font";
            description = "The font to use for monospace text";
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
            noto-fonts-color-emoji
            nerd-fonts.jetbrains-mono
          ];
        };
      };
    };
}
