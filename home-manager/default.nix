{
  config,
  isNixOS,
  lib,
  pkgs,
  inputs,
  user,
  ...
}:
{
  imports = [
    ./hyprland
    ./gui
    ./impermanence.nix # only contains options
    ./shell
  ];

  options.custom = with lib; {
    autologinCommand = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Command to run after autologin";
    };
    fonts = {
      regular = mkOption {
        type = types.str;
        default = "Geist";
        description = "The font to use for regular text";
      };
      weeb = mkOption {
        type = types.str;
        default = "Mamelon";
        description = "The font to use for weeb text";
      };
      monospace = mkOption {
        type = types.str;
        default = "JetBrainsMono Nerd Font";
        # default = "Geist Mono NerdFont";
        description = "The font to use for monospace text";
      };
      packages = mkOption {
        type = types.listOf types.package;
        description = "The packages to install for the fonts";
      };
    };
    headless = mkEnableOption "headless mode" // {
      default = false;
      description = "Whether to enable headless mode, no GUI programs will be available";
    };
    symlinks = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Symlinks to create in the format { dest = src;}";
    };
  };

  config = {
    # setup fonts for other distros, run "fc-cache -f" to refresh fonts
    fonts = {
      fontconfig = {
        enable = true;
        defaultFonts = rec {
          serif = [
            "${config.custom.fonts.regular}"
            "${config.custom.fonts.weeb}"
          ];
          sansSerif = serif;
          monospace = [
            "${config.custom.fonts.monospace}"
            "${config.custom.fonts.weeb}"
          ];
        };
      };
    };

    home = {
      username = user;
      homeDirectory = "/home/${user}";
      # do not change this value
      stateVersion = "23.05";

      sessionVariables = {
        __IS_NIXOS = if isNixOS then "1" else "0";
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
        # ++ (lib.optional config.custom.helix.enable helix)
        # home-manager executable only on nixos
        ++ (lib.optional isNixOS home-manager)
        # handle fonts
        ++ (lib.optionals (!isNixOS) config.custom.fonts.packages);
    };

    # Let Home Manager install and manage itself.
    programs.home-manager.enable = true;

    # create symlinks
    systemd.user.tmpfiles.rules =
      let
        normalizeHome = p: if (lib.hasPrefix "/home" p) then p else "${config.home.homeDirectory}/${p}";
      in
      lib.mapAttrsToList (dest: src: "L+ ${normalizeHome dest} - - - - ${src}") config.custom.symlinks;

    xdg = {
      enable = true;
      userDirs.enable = true;
      mimeApps.enable = true;
    };

    custom = {
      fonts.packages = with pkgs; [
        inputs.mamelon.packages.${system}.default
        nerd-fonts.geist-mono
        nerd-fonts.jetbrains-mono
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-emoji
      ];

      persist = {
        home.directories = [
          "Books"
          "Desktop"
          "Documents"
          "Pictures"
          ".config/libreoffice"
        ];
      };
    };
  };
}
