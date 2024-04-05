{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.custom.terminal;
in
{
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
    };

    shell = {
      profileExtra = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "Extra shell agnostic commands that should be run when initializing a login shell.";
      };

      packages = lib.mkOption {
        type = with lib.types; attrsOf (either str package);
        default = { };
        description = "Attrset of extra shell packages to install and add to pkgs.custom overlay, strings will be converted to writeShellApplication.";
      };

      finalPackages = lib.mkOption {
        type = with lib.types; attrsOf package;
        readOnly = true;
        default = lib.mapAttrs (
          name: pkg:
          if lib.isString pkg then
            pkgs.writeShellApplication {
              inherit name;
              text = pkg;
            }
          else
            pkg
        ) config.custom.shell.packages;
        description = "Extra shell packages to install after all entries have been converted to packages.";
      };
    };
  };
}
