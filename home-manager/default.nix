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
    ./impermanence.nix
    ./programs
    ./shell
  ];

  options.custom = with lib; {
    fonts = {
      regular = mkOption {
        type = types.str;
        default = "Kollektif";
        description = "The font to use for regular text";
      };
      weeb = mkOption {
        type = types.str;
        default = "Mamelon";
        description = "The font to use for weeb text";
      };
      monospace = mkOption {
        type = types.str;
        default = "Maple Mono NF";
        description = "The font to use for monospace text";
      };
      packages = mkOption {
        type = types.listOf types.package;
        description = "The packages to install for the fonts";
      };
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
            "Kollektif"
            "Mamelon"
          ];
          sansSerif = serif;
          monospace = [
            "Maple Mono NF"
            "Mamelon"
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
          rar # includes unrar
          ripgrep
          libreoffice
          trash-cli
          xdg-utils
          # misc utilities for dotfiles written in rust
          custom.dotfiles-rs
        ]
        ++ (lib.optional config.custom.helix.enable helix)
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
      lib.mapAttrsToList (
        dest: src: "L+ ${normalizeHome dest} - - - - ${normalizeHome src}"
      ) config.custom.symlinks;

    xdg = {
      enable = true;
      userDirs.enable = true;
      mimeApps.enable = true;
    };

    custom = {
      fonts.packages = with pkgs; [
        noto-fonts
        noto-fonts-cjk
        noto-fonts-emoji
        iosevka
        maple-mono-NF
        inputs.mamelon.packages.${system}.mamelon
        inputs.kollektif.packages.${system}.kollektif
        (nerdfonts.override { fonts = [ "Iosevka" ]; })
      ];

      persist = {
        home.directories = [
          "Desktop"
          "Documents"
          "Pictures"
          "Books"
        ];
      };
    };
  };
}
