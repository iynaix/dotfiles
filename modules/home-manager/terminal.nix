{
  config,
  lib,
  pkgs,
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
      packages = lib.mkOption {
        type =
          with lib.types;
          attrsOf (oneOf [
            str
            attrs
            package
          ]);
        default = { };
        description = ''
          Attrset of shell packages to install and add to pkgs.custom overlay (for compatibility across multiple shells).
          Both string and attr values will be passed as arguments to writeShellApplication
        '';
        example = ''
          shell.packages = {
            myPackage1 = "echo 'Hello, World!'";
            myPackage2 = {
              runtimeInputs = [ pkgs.hello ];
              text = "hello --greeting 'Hi'";
            };
          }
        '';
      };

      finalPackages = lib.mkOption {
        type = with lib.types; attrsOf package;
        readOnly = true;
        default = lib.mapAttrs (
          name: value:
          if lib.isString value then
            pkgs.writeShellApplication {
              inherit name;
              text = value;
            }
          # packages
          else if lib.isDerivation value then
            value
          # attrs to pass to writeShellApplication
          else
            pkgs.writeShellApplication (value // { inherit name; })
        ) config.custom.shell.packages;
        description = "Extra shell packages to install after all entries have been converted to packages.";
      };
    };
  };
}
