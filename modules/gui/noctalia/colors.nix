{ lib, ... }:
{
  flake.nixosModules.core =
    { pkgs, ... }:
    let
      tomlFormat = pkgs.formats.toml { };
    in
    {
      options.custom = {
        programs.noctalia = {
          colors = lib.mkOption {
            inherit (tomlFormat) type;
            default = { };
            description = ''
              TOML config for noctalia, similar to https://iniox.github.io/#matugen/configuration for
              available options
            '';
          };
        };
      };
    };

  flake.nixosModules.wm =
    { config, pkgs, ... }:
    let
      tomlFormat = pkgs.formats.toml { };
    in
    {
      hj.xdg.config.files."noctalia/user-templates.toml" = {
        generator = tomlFormat.generate "user-template.toml";
        value = {
          config = { };
        }
        // config.custom.programs.noctalia.colors;
      };
    };
}
