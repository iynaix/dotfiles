{
  config,
  user,
  lib,
  ...
}: let
  cfg = config.iynaix-nixos.persist;
in {
  config = {
    # clear /tmp on boot
    boot.tmp.cleanOnBoot = true;

    # root / home filesystem is destroyed and rebuilt on every boot:
    # https://grahamc.com/blog/erase-your-darlings
    boot.initrd.postDeviceCommands = lib.mkAfter ''
      ${lib.optionalString (!cfg.tmpfs && cfg.erase.root) "zfs rollback -r zroot/root@blank"}
      ${lib.optionalString (!cfg.tmpfs && cfg.erase.home) "zfs rollback -r zroot/home@blank"}
    '';

    # create and fix directory permissions so home-manager doesn't error out
    systemd.services.fix-mount-permissions = let
      createOwnedDir = dir: ''
        mkdir -p ${dir}
        chown ${user}:users ${dir}
        chmod 700 ${dir}
      '';
    in {
      script = ''
        ${createOwnedDir "/persist/home"}
        ${createOwnedDir "/persist/home/${user}"}
        ${createOwnedDir "/persist/cache"}
      '';
      wantedBy = ["multi-user.target"];
    };

    # replace root and /or home filesystems with tmpfs
    fileSystems."/" = lib.mkIf (cfg.tmpfs && cfg.erase.root) (lib.mkForce {
      device = "tmpfs";
      fsType = "tmpfs";
      options = ["defaults" "size=1G" "mode=755"];
    });
    fileSystems."/home/${user}" = lib.mkIf (cfg.tmpfs && cfg.erase.home) (lib.mkForce {
      device = "tmpfs";
      fsType = "tmpfs";
      options = ["defaults" "size=1G" "mode=777"];
    });

    # shut sudo up
    security.sudo.extraConfig = "Defaults lecture=never";

    # persisting user passwords
    # https://reddit.com/r/NixOS/comments/o1er2p/tmpfs_as_root_but_without_hardcoding_your/h22f1b9/
    users.mutableUsers = false;
    # create a password with for root and $user with:
    # mkpasswd -m sha-512 'PASSWORD' | sudo tee -a /persist/etc/shadow/root
    users.users.root.hashedPasswordFile = "/persist/etc/shadow/root";
    users.users.${user}.hashedPasswordFile = "/persist/etc/shadow/${user}";

    # setup persistence
    environment.persistence."/persist" = {
      hideMounts = true;

      files = cfg.root.files;
      directories =
        [
          # systemd journal is stored in /var/log/journal
          "/var/log"
        ]
        ++ cfg.root.directories;

      # DO NOT persist anything for home directory as it causes a race condition
    };

    # setup persistence for home manager
    programs.fuse.userAllowOther = true;
    hm = {...} @ hmCfg: let
      hmPersistCfg = hmCfg.config.iynaix.persist;
    in {
      systemd.user.startServices = true;
      home.persistence = {
        "/persist/home/${user}" = {
          allowOther = true;
          removePrefixDirectory = false;

          files = [".Xauthority"] ++ cfg.home.files ++ hmPersistCfg.home.files;
          directories =
            [
              {
                directory = "projects";
                method = "symlink";
              }
            ]
            ++ lib.optionals config.programs.dconf.enable [
              ".cache/dconf"
              ".config/dconf"
            ]
            ++ cfg.home.directories
            ++ hmPersistCfg.home.directories;
        };
        "/persist/cache" = {
          allowOther = true;
          removePrefixDirectory = false;

          directories = hmPersistCfg.cache;
        };
      };
    };
  };
}
