{ lib, ... }:
let
  inherit (lib) mkOption;
in
{
  flake.nixosModules.core =
    { pkgs, ... }:
    let
      tomlFormat = pkgs.formats.toml { };
    in
    {
      options.custom = {
        programs.noctalia = {
          colors = mkOption {
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
      hj.xdg.config.files."noctalia/user-templates.toml".source =
        tomlFormat.generate "user-template.toml"
          ({ config = { }; } // config.custom.programs.noctalia.colors);
    };
}
