{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.iynaix.terminal;
in {
  options.iynaix.terminal = {
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.kitty;
      description = "Terminal package to use.";
    };

    exec = lib.mkOption {
      type = lib.types.str;
      default = "${lib.getExe cfg.package}";
      description = "Terminal command to execute other programs.";
      example = "kitty";
    };

    font = lib.mkOption {
      type = lib.types.str;
      default = config.iynaix.font.monospace;
      description = "Font for the terminal.";
    };

    size = lib.mkOption {
      type = lib.types.int;
      default = 11;
      description = "Font size for the terminal.";
    };

    padding = lib.mkOption {
      type = lib.types.int;
      default = 12;
      description = "Padding for the terminal.";
    };

    opacity = lib.mkOption {
      type = lib.types.float;
      default = 0.7;
      description = "Opacity for the terminal.";
    };

    # create a fake gnome-terminal shell script so xdg terminal applications open in the correct terminal
    # https://unix.stackexchange.com/a/642886
    fakeGnomeTerminal = lib.mkOption {
      type = lib.types.package;
      default = (
        pkgs.writeShellScriptBin "gnome-terminal" ''
          shift

          TITLE="$(basename "$1")"
          if [ -n "$TITLE" ]; then
            ${cfg.exec} -T "$TITLE" "$@"
          else
            ${cfg.exec} "$@"
          fi
        ''
      );
      description = "Fake gnome-terminal shell script so gnome opens terminal applications in the correct terminal.";
    };
  };
}
