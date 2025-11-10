{
  inputs,
  lib,
  self,
  ...
}:
let
  inherit (lib) getExe mkOption;
  mkGhosttyOptions =
    pkgs:
    let
      keyValueSettings = {
        listsAsDuplicateKeys = true;
        mkKeyValue = lib.generators.mkKeyValueDefault { } " = ";
      };
      keyValue = pkgs.formats.keyValue keyValueSettings;
    in
    {
      extraSettings = lib.mkOption {
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
in
{
  flake.wrapperModules.ghostty = inputs.wrappers.lib.wrapModule (
    { config, ... }:
    let
      # adapted from home-manager:
      # https://github.com/nix-community/home-manager/blob/master/modules/programs/ghostty.nix
      toGhosttyConf =
        (config.pkgs.formats.keyValue {
          listsAsDuplicateKeys = true;
          mkKeyValue = lib.generators.mkKeyValueDefault { } " = ";
        }).generate
          "ghostty-config";
      baseGhosttyConf = {
        alpha-blending = "linear-corrected";
        app-notifications = "no-clipboard-copy";
        background-opacity = 0.85;
        confirm-close-surface = false;
        copy-on-select = "clipboard";
        cursor-style = "bar";
        font-size = 10;
        window-decoration = false;
        window-padding-x = 12;
        window-padding-y = 12;
      };
    in
    {
      options = mkGhosttyOptions config.pkgs;

      config.package = config.pkgs.ghostty;
      config.flags = {
        "--config-default-files" = false;
        # NOTE: don't use wrapWithRuntimeConfig as ghostty "helpfully" creates an empty config in the
        # default location
        "--config-file" = toGhosttyConf (baseGhosttyConf // config.extraSettings);
      };
      config.flagSeparator = "=";
    }
  );

  flake.nixosModules.core =
    { config, pkgs, ... }:
    {
      options.custom = {
        # terminal options
        programs.terminal = {
          package = mkOption {
            type = lib.types.package;
            default = pkgs.ghostty;
            description = "Package to use for the terminal";
          };

          app-id = mkOption {
            type = lib.types.str;
            description = "app-id (wm class) for the terminal";
          };

          desktop = mkOption {
            type = lib.types.str;
            default = "${config.custom.programs.terminal.package.pname}.desktop";
            description = "Name of desktop file for the terminal";
          };
        };
        programs.ghostty = mkGhosttyOptions pkgs;
      };
    };

  perSystem =
    { pkgs, ... }:
    {
      packages.ghostty' = (self.wrapperModules.ghostty.apply { inherit pkgs; }).wrapper;
    };

  flake.nixosModules.gui =
    { config, pkgs, ... }:
    {
      nixpkgs.overlays = [
        (_: prev: {
          ghostty =
            (self.wrapperModules.ghostty.apply {
              pkgs = prev;
              extraSettings = {
                # set as default interactive shell, also set $SHELL for nix shell to pick up
                command = "SHELL=${getExe pkgs.fish} fish";
                font-family = config.custom.fonts.monospace;
                font-feature = "zero";
                font-style = "Medium";
              }
              // config.custom.programs.ghostty.extraSettings;
            }).wrapper;
        })
      ];

      environment.systemPackages = [
        pkgs.ghostty # overlay-ed above
      ];

      custom.programs.terminal = {
        app-id = "com.mitchellh.ghostty";
        desktop = "com.mitchellh.ghostty.desktop";
      };
    };
}
