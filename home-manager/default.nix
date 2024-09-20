{
  config,
  isNixOS,
  lib,
  pkgs,
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
        default = "Iosevka Nerd Font Propo";
        description = "The font to use for regular text";
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
    fonts.fontconfig.enable = true;

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
          # for gaming
          heroic
          steam-run
          protonup-qt
          wineWowPackages.waylandFull
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
        (nerdfonts.override { fonts = [ "Iosevka" ]; })
        custom.rofi-themes
      ];

      persist = {
        home.directories = [
          "Desktop"
          "Documents"
          "Pictures"
          "Books"
          "Games"
          ".config/heroic"
        ];
      };
    };
  };
}
