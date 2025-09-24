{
  config,
  host,
  isLaptop,
  lib,
  libCustom,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption types;
  inherit (lib.types) listOf package str;
in
{
  options.custom = {
    persist = {
      home = {
        directories = mkOption {
          type = listOf str;
          default = [ ];
          description = "Directories to persist in home directory";
        };
        files = mkOption {
          type = listOf str;
          default = [ ];
          description = "Files to persist in home directory";
        };
        cache = {
          directories = mkOption {
            type = listOf str;
            default = [ ];
            description = "Directories to persist, but not to snapshot";
          };
          files = mkOption {
            type = listOf str;
            default = [ ];
            description = "Files to persist, but not to snapshot";
          };
        };
      };
    };

    # for shell packages
    shell = {
      packages = mkOption {
        type =
          with types;
          attrsOf (oneOf [
            str
            attrs
            package
          ]);
        default = { };
        apply = libCustom.mkShellPackages;
        description = ''
          Attrset of shell packages to install and add to pkgs.custom overlay (for compatibility across multiple shells).
          Both string and attr values will be passed as arguments to writeShellApplicationCompletions
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
    };

    # hardware options
    backlight.enable = mkEnableOption "Backlight" // {
      default = isLaptop;
    };
    battery.enable = mkEnableOption "Battery" // {
      default = isLaptop;
    };
    nvidia.enable = mkEnableOption "Nvidia GPU" // {
      default = host == "desktop";
    };
    radeon.enable = mkEnableOption "AMD GPU" // {
      default = host == "framework";
    };
    wifi.enable = mkEnableOption "Wifi" // {
      default = isLaptop;
    };
    # dual boot windows
    mswindows = mkEnableOption "Windows" // {
      default = host == "desktop";
    };

    # terminal options
    terminal = {
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
        default = "${config.custom.terminal.package.pname}.desktop";
        description = "Name of desktop file for the terminal";
      };
    };
  };
}
