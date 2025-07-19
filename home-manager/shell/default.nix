{
  config,
  isNixOS,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    attrValues
    mkIf
    mkOption
    ;
  inherit (lib.types)
    float
    int
    package
    str
    ;
in
{
  imports = [
    ./bash.nix
    ./bat.nix
    ./btop.nix
    ./cava.nix
    ./direnv.nix
    ./eza.nix
    ./fish.nix
    ./git.nix
    ./helix.nix
    ./jujutsu.nix
    ./neovim.nix
    ./nix.nix
    ./rice.nix
    ./ripgrep.nix
    ./rust.nix
    ./shell.nix
    ./starship.nix
    ./tmux.nix
    ./typescript.nix
    ./yazi.nix
    ./yt-dlp.nix
    ./zoxide.nix
  ];

  options.custom = {
    terminal = {
      package = mkOption {
        type = package;
        default = config.programs.ghostty.package;
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

      font = mkOption {
        type = str;
        default = config.custom.fonts.monospace;
        description = "Font for the terminal.";
      };

      size = mkOption {
        type = int;
        default = 10;
        description = "Font size for the terminal.";
      };

      padding = mkOption {
        type = int;
        default = 12;
        description = "Padding for the terminal.";
      };

      opacity = mkOption {
        type = float;
        default = 0.85;
        description = "Opacity for the terminal.";
      };
    };

  };

  config = {
    home.packages =
      with pkgs;
      [
        # dysk # better disk info
        ets # add timestamp to beginning of each line
        fd # better find
        fx # terminal json viewer and processor
        htop
        jq
        sd # better sed
        # grep, with boolean query patterns, e.g. ug --files -e "A" --and "B"
        ugrep
      ]
      # add custom user created shell packages
      ++ (attrValues config.custom.shell.packages);

    # add custom user created shell packages to pkgs.custom.shell
    nixpkgs.overlays = mkIf (!isNixOS) [
      (_: prev: {
        custom = (prev.custom or { }) // {
          shell = config.custom.shell.packages;
        };
      })
    ];

    programs = {
      fzf = {
        enable = true;
        enableBashIntegration = true;
        enableFishIntegration = true;
      };
    };

    custom.persist = {
      home = {
        cache.directories = [ ".local/share/zoxide" ];
      };
    };
  };
}
