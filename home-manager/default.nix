{
  config,
  isNixOS,
  lib,
  pkgs,
  user,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    optionals
    ;
  inherit (lib.types)
    attrsOf
    nullOr
    str
    ;
in
{
  options.custom = {
    autologinCommand = mkOption {
      type = nullOr str;
      default = null;
      description = "Command to run after autologin";
    };
    specialisation = {
      current = mkOption {
        type = str;
        default = "";
        description = "The current specialisation being used";
      };

      hyprland.enable = mkEnableOption "hyprland specialisation";
      niri.enable = mkEnableOption "niri specialisation";
      mango.enable = mkEnableOption "mango specialisation";
    };
    symlinks = mkOption {
      type = attrsOf str;
      default = { };
      description = "Symlinks to create in the format { dest = src;}";
    };
  };

  config = {
    home = {
      username = user;
      homeDirectory = "/home/${user}";
      # do not change this value
      stateVersion = "23.05";

      sessionVariables = {
        __IS_NIXOS = if isNixOS then "1" else "0";
        __SPECIALISATION = config.custom.specialisation.current;
        NIXPKGS_ALLOW_UNFREE = "1";
      };

      packages =
        with pkgs;
        [
          curl
          gzip
          libreoffice
          trash-cli
          xdg-utils
        ]
        # home-manager executable only on nixos
        ++ (optionals isNixOS [ home-manager ]);
    };

    # Let Home Manager install and manage itself.
    programs.home-manager.enable = true;

    xdg = {
      enable = true;
      userDirs.enable = true;
      mimeApps.enable = true;
    };

    custom = {
      persist = {
        home.directories = [
          "Desktop"
          "Documents"
          "Pictures"
          ".config/libreoffice"
        ];
      };
    };
  };
}
