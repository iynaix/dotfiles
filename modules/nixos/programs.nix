{
  config,
  isLaptop,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom;
in
{
  options.custom = {
    ### NIXOS LEVEL OPTIONS ###
    bittorrent.enable = lib.mkEnableOption "Torrenting Applications";
    distrobox.enable = lib.mkEnableOption "distrobox";
    docker.enable = lib.mkEnableOption "docker" // {
      default = cfg.distrobox.enable;
    };
    keyd.enable = lib.mkEnableOption "keyd" // {
      default = isLaptop;
    };
    plasma.enable = lib.mkEnableOption "Plasma Desktop";
    sops.enable = lib.mkEnableOption "sops" // {
      default = true;
    };
    syncoid.enable = lib.mkEnableOption "syncoid";
    vercel.enable = lib.mkEnableOption "Vercel Backups";
    vm.enable = lib.mkEnableOption "VM support";

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
            pkgs.custom.writeShellApplicationCompletions (value // { inherit name; })
        ) config.custom.shell.packages;
        description = "Extra shell packages to install after all entries have been converted to packages.";
      };
    };
  };
}
