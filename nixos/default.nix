{
  config,
  dots,
  lib,
  libCustom,
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
    attrs
    attrsOf
    oneOf
    package
    str
    ;
in
{
  options.custom = {
    shell = {
      packages = mkOption {
        type = attrsOf (oneOf [
          str
          attrs
          package
        ]);
        apply = libCustom.mkShellPackages;
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
    };
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
      variables = {
        TERMINAL = getExe config.hm.custom.terminal.package;
        EDITOR = "nvim";
        VISUAL = "nvim";
        NIXPKGS_ALLOW_UNFREE = "1";
        # xdg
        XDG_CACHE_HOME = config.hj.xdg.cache.directory;
        XDG_CONFIG_HOME = config.hj.xdg.config.directory;
        XDG_DATA_HOME = config.hj.xdg.data.directory;
        XDG_STATE_HOME = config.hj.xdg.state.directory;
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
          htop
          jq
          killall
          procs # better ps
          (hiPrio procps) # for uptime
          sd # better sed
          ugrep # grep, with boolean query patterns, e.g. ug --files -e "A" --and "B"
          # use the package configured by nvf
          (custom.neovim-iynaix.override { inherit dots host; })
        ]
        # add custom user created shell packages
        ++ (attrValues (config.custom.shell.packages // config.hm.custom.shell.packages));
    };

    nixpkgs = {
      config.allowUnfree = true;

      # add custom user created shell packages to pkgs.custom.shell
      overlays = [
        (_: prev: {
          custom = (prev.custom or { }) // {
            shell = config.custom.shell.packages // config.hm.custom.shell.packages;
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

    xdg = {
      # use mimetypes defined from home-manager
      mime =
        let
          hmMime = config.hm.xdg.mimeApps;
        in
        {
          enable = true;
          inherit (hmMime) defaultApplications;
          addedAssociations = hmMime.associations.added;
          removedAssociations = hmMime.associations.removed;
        };
    };

    custom.persist = {
      root.directories = optionals config.custom.hardware.wifi.enable [ "/etc/NetworkManager" ];
      root.cache.directories = [ "/var/lib/systemd/coredump" ];

      home.directories = [ ".local/state/wireplumber" ];
    };
  };
}
