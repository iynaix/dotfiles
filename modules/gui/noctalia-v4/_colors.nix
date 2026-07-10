{ lib, ... }:
{
  flake.modules.nixos.core =
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

  flake.modules.nixos.wm =
    { config, pkgs, ... }:
    let
      tomlFormat = pkgs.formats.toml { };
    in
    {
      custom.programs =
        let
          inherit (config.custom.hardware) monitors;
        in
        {
          # use colors from the largest monitor
          noctalia.settingsReducers = lib.mkIf ((lib.length monitors) > 1) [
            (
              prev:
              lib.recursiveUpdate prev {
                colorSchemes.monitorForColors =
                  (monitors |> lib.sortOn (m: m.width / m.scale * m.height / m.scale) |> lib.last).name;
              }
            )
          ];
        };

      hj.xdg.config.files."noctalia/user-templates.toml" = {
        generator = tomlFormat.generate "user-template.toml";
        value = {
          config = { };
        }
        // config.custom.programs.noctalia.colors;
      };
    };
}
