{
  config,
  lib,
  pkgs,
  user,
  ...
}:
let
  cfg = config.custom.persist;
  hmPersistCfg = config.hm.custom.persist;
in
{
  options.custom = with lib; {
    persist = {
      root = {
        directories = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Directories to persist in root filesystem";
        };
        files = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Files to persist in root filesystem";
        };
        cache = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Directories to persist, but not to snapshot";
        };
      };
      home = {
        directories = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Directories to persist in home directory";
        };
        files = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Files to persist in home directory";
        };
      };
    };
  };

  config = {
    # clear /tmp on boot, since it's a zfs dataset
    boot.tmp.cleanOnBoot = true;

    # root and home on tmpfs
    # neededForBoot is required, so there won't be permission errors creating directories or symlinks
    # https://github.com/nix-community/impermanence/issues/149#issuecomment-1806604102
    fileSystems."/" = lib.mkForce {
      device = "tmpfs";
      fsType = "tmpfs";
      neededForBoot = true;
      options = [
        "defaults"
        "size=1G"
        "mode=755"
      ];
    };

    # shut sudo up
    security.sudo.extraConfig = "Defaults lecture=never";

    custom.shell.packages = {
      # show all files stored on tmpfs, useful for finding files to persist
      show-tmpfs = {
        runtimeInputs = [ pkgs.fd ];
        text =
          let
            wallustExcludes = lib.pipe config.hm.custom.wallust.templates [
              lib.attrValues
              (map (a: a.target))
              (lib.filter (t: !(lib.hasInfix "wallust" t)))
              (map (t: ''--exclude "${t}" \''))
              lib.concatLines
            ];
          in
          ''
            sudo fd --one-file-system --base-directory / --type f --hidden \
              --exclude "/etc/{ssh,machine-id,passwd,shadow}" \
              --exclude "*.timer" \
              --exclude "/var/lib/NetworkManager" \
              --exclude "${config.hm.xdg.cacheHome}/{bat,fontconfig,mpv,nvidia,nvim/catppuccin,pre-commit,swww,wallust}" \
              ${wallustExcludes}  --exec ls -lS | sort -rn -k5 | awk '{print $5, $9}'
          '';
      };
    };

    # setup persistence
    environment.persistence = {
      "/persist" = {
        hideMounts = true;
        files = [ "/etc/machine-id" ] ++ cfg.root.files;
        directories = [
          "/var/log" # systemd journal is stored in /var/log/journal
          "/var/lib/nixos" # for persisting user uids and gids
        ] ++ cfg.root.directories;

        users.${user} = {
          files = cfg.home.files ++ hmPersistCfg.home.files;
          directories = [
            "projects"
            ".cache/dconf"
            ".config/dconf"
          ] ++ cfg.home.directories ++ hmPersistCfg.home.directories;
        };
      };

      "/persist/cache" = {
        hideMounts = true;
        directories = cfg.root.cache;

        users.${user} = {
          directories = hmPersistCfg.home.cache;
        };
      };
    };

    hm.xdg.dataFile."impermanence.txt".text =
      let
        getDirPath = d: prefix: "${prefix}${d.dirPath}";
        getFilePath = f: prefix: "${prefix}${f.filePath}";
        persistCfg = config.environment.persistence."/persist";
        persistCacheCfg = config.environment.persistence."/persist/cache";
        allDirectories =
          map (d: getDirPath d "/persist") (persistCfg.directories ++ persistCfg.users.${user}.directories)
          ++ map (d: getDirPath d "/persist/cache") (
            persistCacheCfg.directories ++ persistCacheCfg.users.${user}.directories
          );
        allFiles = map (f: getFilePath f "/persist") (persistCfg.files ++ persistCfg.users.${user}.files);
        sort-u = arr: lib.concatLines (lib.sort lib.lessThan (lib.unique arr));
      in
      ''
        # Directories
        ${sort-u allDirectories}
        # Files
        ${sort-u allFiles}
      '';
  };
}
