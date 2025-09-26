{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  tomlFormat = pkgs.formats.toml { };
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
              (tomlFormat.generate "helix-config" helixConf)
            ];
          };
        }
      )
    ];

    environment.systemPackages = [ pkgs.helix ];
  };
}
