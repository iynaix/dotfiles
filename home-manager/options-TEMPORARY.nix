{
  lib,
  libCustom,
  pkgs,
  user,
  ...
}:
let
  inherit (lib) mkOption types;
  inherit (lib.types)
    listOf
    package
    str
    ;
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
  };

  config = {
    home = {
      username = user;
      homeDirectory = "/home/${user}";
      # do not change this value
      stateVersion = "23.05";

      # home-manager executable only on nixos
      packages = [ pkgs.home-manager ];
    };

    # Let Home Manager install and manage itself.
    programs.home-manager.enable = true;

    xdg.configFile."gtk-3.0/bookmarks".enable = false;

    programs.niri.settings = lib.mkForce { };

  };
}
