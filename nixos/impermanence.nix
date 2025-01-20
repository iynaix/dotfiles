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
  assertNoHomeDirs =
    paths:
    assert (lib.assertMsg (!lib.any (lib.hasPrefix "/home") paths) "/home used in a root persist!");
    paths;
in
{
  options.custom = with lib; {
    persist = {
      root = {
        directories = mkOption {
          type = types.listOf types.str;
          default = [ ];
          apply = assertNoHomeDirs;
          description = "Directories to persist in root filesystem";
        };
        files = mkOption {
          type = types.listOf types.str;
          default = [ ];
          apply = assertNoHomeDirs;
          description = "Files to persist in root filesystem";
        };
        cache = {
          directories = mkOption {
            type = types.listOf types.str;
            default = [ ];
            apply = assertNoHomeDirs;
            description = "Directories to persist, but not to snapshot";
          };
          files = mkOption {
            type = types.listOf types.str;
            default = [ ];
            apply = assertNoHomeDirs;
            description = "Files to persist, but not to snapshot";
          };
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
              --exclude "/etc/{ssh,passwd,shadow}" \
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
        files = lib.unique cfg.root.files;
        directories = lib.unique (
          [
            "/var/log" # systemd journal is stored in /var/log/journal
            "/var/lib/nixos" # for persisting user uids and gids
          ]
          ++ cfg.root.directories
        );

        users.${user} = {
          files = lib.unique (cfg.home.files ++ hmPersistCfg.home.files);
          directories = lib.unique (
            [
              "projects"
              ".cache/dconf"
              ".config/dconf"
            ]
            ++ cfg.home.directories
            ++ hmPersistCfg.home.directories
          );
        };
      };

      # cache are files that should be persisted, but not to snapshot
      # e.g. npm, cargo cache etc, that could always be redownloaded
      "/cache" = {
        hideMounts = true;
        files = lib.unique cfg.root.cache.files;
        directories = lib.unique cfg.root.cache.directories;

        users.${user} = {
          files = lib.unique hmPersistCfg.home.cache.files;
          directories = lib.unique hmPersistCfg.home.cache.directories;
        };
      };
    };

    hm.xdg.stateFile."impermanence.json".text =
      let
        getDirPath = prefix: d: "${prefix}${d.dirPath}";
        getFilePath = prefix: f: "${prefix}${f.filePath}";
        persistCfg = config.environment.persistence."/persist";
        persistCacheCfg = config.environment.persistence."/cache";
        allDirectories =
          map (getDirPath "/persist") (persistCfg.directories ++ persistCfg.users.${user}.directories)
          ++ map (getDirPath "/cache") (
            persistCacheCfg.directories ++ persistCacheCfg.users.${user}.directories
          );
        allFiles =
          map (getFilePath "/persist") (persistCfg.files ++ persistCfg.users.${user}.files)
          ++ map (getFilePath "/cache") (persistCacheCfg.files ++ persistCacheCfg.users.${user}.files);
        sort-uniq = arr: lib.sort lib.lessThan (lib.unique arr);
      in
      lib.strings.toJSON {
        directories = sort-uniq allDirectories;
        files = sort-uniq allFiles;
      };
  };
}
