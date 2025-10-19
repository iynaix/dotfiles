{ inputs, lib, ... }:
let
  inherit (lib) mkOption types;
  inherit (types) package str;
in
{
  flake.nixosModules.core =
    { config, pkgs, ... }:
    let
      keyValueSettings = {
        listsAsDuplicateKeys = true;
        mkKeyValue = lib.generators.mkKeyValueDefault { } " = ";
      };
      keyValue = pkgs.formats.keyValue keyValueSettings;
    in
    {
      options.custom = {
        # terminal options
        programs.terminal = {
          package = mkOption {
            type = package;
            default = pkgs.ghostty;
            description = "Package to use for the terminal";
          };

          app-id = mkOption {
            type = str;
            description = "app-id (wm class) for the terminal";
          };

          desktop = mkOption {
            type = str;
            default = "${config.custom.programs.terminal.package.pname}.desktop";
            description = "Name of desktop file for the terminal";
          };
        };
        programs.ghostty.settings = lib.mkOption {
          inherit (keyValue) type;
          default = { };
          example = lib.literalExpression ''
            {
              theme = "catppuccin-mocha";
              font-size = 10;
              keybind = [
                "ctrl+h=goto_split:left"
                "ctrl+l=goto_split:right"
              ];
            }
          '';
          description = ''
            Configuration written to {file}`$XDG_CONFIG_HOME/ghostty/config`.

            See <https://ghostty.org/docs/config/reference> for more information.
          '';
        };
      };
    };

  flake.nixosModules.gui =
    { config, pkgs, ... }:
    let
      # adapted from home-manager:
      # https://github.com/nix-community/home-manager/blob/master/modules/programs/ghostty.nix
      toGhosttyConf =
        (pkgs.formats.keyValue {
          listsAsDuplicateKeys = true;
          mkKeyValue = lib.generators.mkKeyValueDefault { } " = ";
        }).generate
          "ghostty-config";
      padding = 12;
      ghostty' = inputs.wrappers.lib.wrapPackage {
        inherit pkgs;
        package = pkgs.ghostty;
        flags = {
          "--config-default-files" = false;
          # NOTE: don't use wrapWithRuntimeConfig as ghostty "helpfully" creates an empty config in the
          # default location
          "--config-file" = toGhosttyConf config.custom.programs.ghostty.settings;
        };
        flagSeparator = "=";
      };
    in
    {
      custom.programs.ghostty.settings = {
        alpha-blending = "linear-corrected";
        app-notifications = "no-clipboard-copy";
        background-opacity = 0.85;
        # set as default interactive shell, also set $SHELL for nix shell to pick up
        command = "SHELL=${lib.getExe pkgs.fish} ${lib.getExe pkgs.fish}";
        confirm-close-surface = false;
        copy-on-select = "clipboard";
        cursor-style = "bar";
        font-family = config.custom.fonts.monospace;
        font-feature = "zero";
        font-size = 10;
        font-style = "Medium";
        window-decoration = false;
        window-padding-x = padding;
        window-padding-y = padding;
      };

      environment.systemPackages = [ ghostty' ];

      custom.programs.terminal = {
        app-id = "com.mitchellh.ghostty";
        desktop = "com.mitchellh.ghostty.desktop";
      };
    };
}
