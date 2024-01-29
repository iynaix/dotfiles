{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.custom.terminal;
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
  options.custom = {
    terminal = {
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.kitty;
        description = "Terminal package to use.";
      };

      exec = lib.mkOption {
        type = lib.types.str;
        default = lib.getExe cfg.package;
        description = "Terminal command to execute other programs.";
      };

      font = lib.mkOption {
        type = lib.types.str;
        default = config.custom.fonts.monospace;
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
        type = lib.types.str;
        default = "0.8";
        description = "Opacity for the terminal.";
      };

      # create a fake gnome-terminal shell script so xdg terminal applications open in the correct terminal
      # https://unix.stackexchange.com/a/642886
      fakeGnomeTerminal = lib.mkOption {
        type = lib.types.package;
        description = "Fake gnome-terminal executable so nemo opens the correct terminal.";
      };
    };

    shell = {
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
  };
}
