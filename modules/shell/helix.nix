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
      (_: _prev: {
        helix = {
          flags = {
            "--config" = tomlFormat.generate "config.toml" helixConf;
          };
        };
      })
    ];

    environment.systemPackages = [ pkgs.helix ];
  };
}
