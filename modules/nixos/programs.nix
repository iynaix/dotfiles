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
    distrobox.enable = lib.mkEnableOption "distrobox";
    docker.enable = lib.mkEnableOption "docker" // {
      default = cfg.distrobox.enable;
    };
    hyprland.enable = lib.mkEnableOption "hyprland (nixos)" // {
      default = true;
    };
    keyd.enable = lib.mkEnableOption "keyd" // {
      default = isLaptop;
    };
    sops.enable = lib.mkEnableOption "sops" // {
      default = true;
    };
    syncoid.enable = lib.mkEnableOption "syncoid";
    bittorrent.enable = lib.mkEnableOption "Torrenting Applications";
    vercel.enable = lib.mkEnableOption "Vercel Backups";
    vm.enable = lib.mkEnableOption "VM support";

    shell = {
      packages = lib.mkOption {
        type = with lib.types; attrsOf (either str attrs);
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
          name: attrs:
          if lib.isString attrs then
            pkgs.writeShellApplication {
              inherit name;
              text = attrs;
            }
          else
            pkgs.writeShellApplication (attrs // { inherit name; })
        ) config.custom.shell.packages;
        description = "Extra shell packages to install after all entries have been converted to packages.";
      };
    };
  };
}
