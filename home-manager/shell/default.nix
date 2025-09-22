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
    package
    str
    ;
in
{
  options.custom = {
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
        procs # better ps
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
