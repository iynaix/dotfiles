{ lib, ... }:
{
  flake.nixosModules.core =
    { config, pkgs, ... }:
    let
      inherit (config.custom.constants) host user;
      cfg = config.custom.persist;
      assertNoHomeDirs =
        paths:
        assert (lib.assertMsg (!lib.any (lib.hasPrefix "/home") paths) "/home used in a root persist!");
        paths;
      # show all files stored on tmpfs, useful for finding files to persist
      show-tmpfs = pkgs.writeShellApplication {
        name = "show-tmpfs";
        runtimeInputs = [ pkgs.fd ];
        text = /* sh */ ''
          sudo fd --one-file-system --base-directory / --type f --hidden \
            --exclude "/etc/{ssh,passwd,shadow}" \
            --exclude "*.timer" \
            --exclude "/var/lib/NetworkManager" \
            --exclude "${config.hj.xdg.cache.directory}/{bat,fontconfig,mesa_shader_cache,mpv,noctalia,nvim,pre-commit,radv_builtin_shaders,fish,nvf}" \
            --exec ls -lS | sort -rn -k5 | awk '{print $5, $9}'
        '';
      };
    in
    {
      options.custom = {
        persist = {
          root = {
            directories = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              apply = assertNoHomeDirs;
              description = "Directories to persist in root filesystem";
            };
            files = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              apply = assertNoHomeDirs;
              description = "Files to persist in root filesystem";
            };
            cache = {
              directories = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                apply = assertNoHomeDirs;
                description = "Directories to persist, but not to snapshot";
              };
              files = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                apply = assertNoHomeDirs;
                description = "Files to persist, but not to snapshot";
              };
            };
          };
          home = {
            directories = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Directories to persist in home directory";
            };
            files = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Files to persist in home directory";
            };
            cache = {
              directories = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "Directories to persist, but not to snapshot";
              };
              files = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "Files to persist, but not to snapshot";
              };
            };
          };
        };
      };

      config = {
        # clear /tmp on boot, since it's a zfs dataset
        boot.tmp.cleanOnBoot = true;

        # root and home on tmpfs
        fileSystems."/" = lib.mkForce {
          device = "tmpfs";
          fsType = "tmpfs";
          options = [
            "defaults"
            # whatever size feels comfortable, smaller is better
            # a good default is to start with 1G, having a small tmpfs acts as a tripwire hinting that there is something
            # you should probably persist, but haven't done so
            # "size=1G"
            "size=256M"
            "mode=755"
          ];
        };

        # uncomment to use separate home dataset
        # neededForBoot is required, so there won't be permission errors creating directories or symlinks
        # https://github.com/nix-community/impermanence/issues/149#issuecomment-1806604102
        # fileSystems."/home" = lib.mkForce {
        #   device = "tmpfs";
        #   fsType = "tmpfs";
        #   neededForBoot = true;
        #   options = [
        #     "defaults"
        #      # whatever size feels comfortable, smaller is better
        #     "size=1G"
        #     "mode=755"
        #   ];
        # };

        # shut sudo up
        security.sudo.extraConfig = "Defaults lecture=never";

        environment.systemPackages = [
          show-tmpfs
        ];

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
              files = lib.unique cfg.home.files;
              directories = lib.unique (
                [
                  "Desktop"
                  "Documents"
                  "Pictures"
                  "projects"
                ]
                ++ lib.optionals (host != "desktop") [
                  "Downloads"
                ]
                ++ cfg.home.directories
              );
            };
          };

          # cache are files that should be persisted, but not to snapshot
          # e.g. npm, cargo cache etc, that could always be redownloaded
          "/cache" = {
            hideMounts = true;
            files = lib.unique cfg.root.cache.files;
            directories = [ "/var/lib/systemd/coredump" ] ++ lib.unique cfg.root.cache.directories;

            users.${user} = {
              files = lib.unique cfg.home.cache.files;
              directories = lib.unique cfg.home.cache.directories;
            };
          };
        };

        hj.xdg.state.files."impermanence.txt".text =
          let
            getDirPath = prefix: d: "${prefix}${d.dirPath}/";
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
          in
          (allDirectories ++ allFiles) |> lib.unique |> lib.sort lib.lessThan |> lib.concatLines;
      };
    };
}
