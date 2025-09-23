{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  toHelixConf = pkgs.formats.toml { };
  helixConf = {
    theme = "tokyonight";
  };
in
{
  options.custom = {
    programs.helix.enable = mkEnableOption "helix";
  };

  config = mkIf config.custom.programs.helix.enable {
    custom.wrappers = [
      (
        { pkgs, ... }:
        {
          wrappers.helix = {
            basePackage = pkgs.helix;
            prependFlags = [
              "--config"
              (toHelixConf.generate "helix-config" helixConf)
            ];
          };
        }
      )
    ];

    environment.systemPackages = [ pkgs.helix ];
  };
}
