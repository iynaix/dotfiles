{
  tags = [ "gui" ];

  config =
    { lib, pkgs, ... }:
    let
      tomlFormat = pkgs.formats.toml { };
    in
    {
      # user-templates option should be available as a dummy option
      # even if there is no wm, unlike noctalia itself
      options.custom = {
        programs.noctalia = {
          user-templates = lib.mkOption {
            inherit (tomlFormat) type;
            default = { };
            description = ''
              TOML config for noctalia user templates, see
              https://docs.noctalia.dev/noctalia/theming/app-theming/?section=user-templates#user-templates
              for available options
            '';
          };
        };
      };
    };
}
