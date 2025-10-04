{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) getExe mkOption types;
  inherit (types) package str;
  # adapted from home-manager:
  # https://github.com/nix-community/home-manager/blob/master/modules/programs/ghostty.nix
  toGhosttyConf =
    (pkgs.formats.keyValue {
      listsAsDuplicateKeys = true;
      mkKeyValue = lib.generators.mkKeyValueDefault { } " = ";
    }).generate
      "ghostty-config";

  padding = 12;
  fishPath = getExe pkgs.fish;

  ghosttyConf = {
    alpha-blending = "linear-corrected";
    app-notifications = "no-clipboard-copy";
    background-opacity =
      0.85
      # more opaque on niri as there is no blur
      + (if (config.custom.wm == "niri" && !config.custom.programs.niri.blur.enable) then 0.1 else 0);
    # set as default interactive shell, also set $SHELL for nix shell to pick up
    command = "SHELL=${fishPath} ${fishPath}";
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
  };

  config = {
    # re-enable the wrapper when desktop files are patched
    # https://github.com/Lassulus/wrappers/issues/3
    # custom.wrappers = [
    #   (_: _prev: {
    #     ghostty = {
    #       flags = {
    #         "--config-default-files" = false;
    #         # NOTE: don't use wrapWithRuntimeConfig as ghostty "helpfully" creates an empty config in the
    #         # default location
    #         "--config-file" = toGhosttyConf ghosttyConf;
    #       };
    #       flagSeparator = "=";
    #     };
    #   })
    # ];

    environment.systemPackages = [ pkgs.ghostty ];

    hj.xdg.config.files."ghostty/config".source = toGhosttyConf ghosttyConf;

    custom.programs.terminal = {
      app-id = "com.mitchellh.ghostty";
      desktop = "com.mitchellh.ghostty.desktop";
    };
  };
}
