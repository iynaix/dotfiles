{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.iynaix.terminal;
  functionModule = lib.types.submodule {
    options = {
      bashBody = lib.mkOption {
        type = lib.types.lines;
        description = "The function body for bash.";
      };
      bashCompletion = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "The function completion body for bash.";
      };
      fishBody = lib.mkOption {
        type = lib.types.lines;
        description = "The function body for bash.";
      };
      fishCompletion = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "The completion body for fish.";
      };
    };
  };
in {
  options.iynaix.terminal = {
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.kitty;
      description = "Terminal package to use.";
    };

    exec = lib.mkOption {
      type = lib.types.str;
      default =
        if cfg.package == pkgs.kitty
        then "${cfg.package}/bin/kitty"
        else "${lib.getExe cfg.package}";
      description = "Terminal command to execute other programs.";
    };

    font = lib.mkOption {
      type = lib.types.str;
      default = config.iynaix.fonts.monospace;
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
        pkgs.writeShellApplication {
          name = "gnome-terminal";
          text = ''
            shift

            TITLE="$(basename "$1")"
            if [ -n "$TITLE" ]; then
              ${cfg.exec} -T "$TITLE" "$@"
            else
              ${cfg.exec} "$@"
            fi
          '';
        }
      );
      description = "Fake gnome-terminal shell script so gnome opens terminal applications in the correct terminal.";
    };
  };

  options.iynaix.shell = {
    interactive = lib.mkOption {
      type = lib.types.enum ["bash" "fish"];
      default = "fish";
      description = "Interactive shell to use.";
    };
    initExtra = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra shell agnostic commands that should be run when initializing an interactive shell.";
    };
    profileExtra = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra shell agnostic commands that should be run when initializing a login shell.";
    };
    functions = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.lines functionModule);
      example = lib.literalExpression ''
        foo = "echo foo";
        bar = {
          bashBody = "echo bar";
          fishBody = "echo bar";
        };
      '';
      default = {};
      description = "Extra shell agnostic functions.";
    };
  };
}
