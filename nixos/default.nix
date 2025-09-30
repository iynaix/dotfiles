{
  config,
  dots,
  isNixOS,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    attrValues
    getExe
    mapAttrsToList
    mkForce
    mkIf
    mkOption
    optionals
    ;
  inherit (lib.types)
    attrsOf
    str
    ;
in
{
  options.custom = {
    symlinks = mkOption {
      type = attrsOf str;
      default = { };
      description = "Symlinks to create in the format { dest = src;}";
    };
  };

  config = {
    # automount disks
    services.gvfs.enable = true;
    # services.devmon.enable = true;
    programs.dconf.enable = true;

    environment = {
      variables =
        let
          homeDir = config.hj.directory;
        in
        {
          TERMINAL = getExe config.custom.terminal.package;
          EDITOR = "nvim";
          VISUAL = "nvim";
          __IS_NIXOS = if isNixOS then "1" else "0";
          NIXPKGS_ALLOW_UNFREE = "1";
          # xdg
          XDG_CACHE_HOME = config.hj.xdg.cache.directory;
          XDG_CONFIG_HOME = config.hj.xdg.config.directory;
          XDG_DATA_HOME = config.hj.xdg.data.directory;
          XDG_STATE_HOME = config.hj.xdg.state.directory;
          # xdg user dirs
          XDG_DESKTOP_DIR = "${homeDir}/Desktop";
          XDG_DOCUMENTS_DIR = "${homeDir}/Documents";
          XDG_DOWNLOAD_DIR = "${homeDir}/Downloads";
          XDG_MUSIC_DIR = "${homeDir}/Music";
          XDG_PICTURES_DIR = "${homeDir}/Pictures";
          XDG_PUBLICSHARE_DIR = "${homeDir}/Public";
          XDG_TEMPLATES_DIR = "${homeDir}/Templates";
          XDG_VIDEOS_DIR = "${homeDir}/Videos";
        };

      systemPackages =
        with pkgs;
        [
          bonk # mkdir and touch in one
          curl
          # dysk # better disk info
          ets # add timestamp to beginning of each line
          fd # better find
          fx # terminal json viewer and processor
          gzip
          htop
          jq
          killall
          procs # better ps
          (hiPrio procps) # for uptime
          sd # better sed
          trash-cli
          ugrep # grep, with boolean query patterns, e.g. ug --files -e "A" --and "B"
          xdg-utils
          # use the package configured by nvf
          (custom.neovim-iynaix.override { inherit dots host; })
        ]
        # add custom user created shell packages
        ++ (attrValues config.custom.shell.packages);

    };

    nixpkgs = {
      config.allowUnfree = true;

      # add custom user created shell packages to pkgs.custom.shell
      overlays = [
        (_: prev: {
          custom = (prev.custom or { }) // {
            shell = config.custom.shell.packages;
          };
        })
      ];
    };

    # thanks for not fucking wasting my time
    hjem.clobberByDefault = true;

    # create symlink to dotfiles from default /etc/nixos
    custom.symlinks = {
      "/etc/nixos" = "/persist${config.hj.directory}/projects/dotfiles";
    };

    # create symlinks
    systemd.tmpfiles.rules = [
      # cleanup systemd coredumps once a week
      "D! /var/lib/systemd/coredump root root 7d"
    ]
    ++ (mapAttrsToList (dest: src: "L+ ${dest} - - - - ${src}") config.custom.symlinks);

    programs = {
      file-roller.enable = true;
      git.enable = true;

      # bye bye nano
      nano.enable = mkForce false;
    };

    # use gtk theme on qt apps
    qt = mkIf (config.custom.wm != "tty") {
      enable = true;
      platformTheme = "qt5ct";
      style = "kvantum";
    };

    xdg.mime.enable = true;

    custom.persist = {
      root.directories = optionals config.custom.hardware.wifi.enable [ "/etc/NetworkManager" ];
      root.cache.directories = [ "/var/lib/systemd/coredump" ];

      home.directories = [
        "Desktop"
        "Documents"
        "Pictures"
        ".local/state/wireplumber"
      ];
    };
  };
}
