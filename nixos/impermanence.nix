{
  config,
  user,
  lib,
  ...
}: let
  cfg = config.iynaix-nixos.persist;
in {
  config = lib.mkIf config.iynaix-nixos.zfs.enable {
    # root / home filesystem is destroyed and rebuilt on every boot:
    # https://grahamc.com/blog/erase-your-darlings
    boot.initrd.postDeviceCommands = lib.mkIf (!cfg.tmpfs) (lib.mkAfter ''
      ${lib.optionalString (cfg.erase.root) "zfs rollback -r zroot/local/root@blank"}
      ${lib.optionalString (cfg.erase.home) "zfs rollback -r zroot/safe/home@blank"}
    '');

    # replace root and /or home filesystems with tmpfs
    fileSystems."/" = lib.mkIf (cfg.tmpfs && cfg.erase.root) (lib.mkForce {
      device = "tmpfs";
      fsType = "tmpfs";
      options = ["defaults" "size=1G" "mode=755"];
    });
    fileSystems."/home/${user}" = lib.mkIf (cfg.tmpfs && cfg.erase.home) (lib.mkForce {
      device = "tmpfs";
      fsType = "tmpfs";
      options = ["defaults" "size=3G" "mode=777"];
    });

    fileSystems."/persist".neededForBoot = true;

    # persisting user passwords
    # https://reddit.com/r/NixOS/comments/o1er2p/tmpfs_as_root_but_without_hardcoding_your/h22f1b9/
    users.mutableUsers = false;
    # create a password with for root and $user with:
    # mkpasswd -m sha-512 'PASSWORD' | sudo tee -a /persist/etc/shadow/root
    users.users.root.passwordFile = "/persist/etc/shadow/root";
    users.users.${user}.passwordFile = "/persist/etc/shadow/${user}";

    # setup persistence
    environment.persistence."/persist" = {
      hideMounts = true;

      files = cfg.root.files;
      directories = ["/var/log"] ++ cfg.root.directories;

      # persist for home directory
      # users.${user} = {
      #   directories =
      #     # [
      #     #   ".local/state/home-manager"
      #     #   ".local/state/nix/profiles"
      #     # ]
      #     # ++
      # };
    };

    # setup persistence for home manager
    programs.fuse.userAllowOther = true;
    hm = {...} @ hmCfg: let
      persistCfg = hmCfg.config.iynaix.persist;
    in {
      systemd.user.startServices = true;
      home.persistence."/persist/home/${user}" = {
        allowOther = true;
        removePrefixDirectory = false;

        files = [".Xauthority"] ++ cfg.home.files ++ persistCfg.home.files;
        directories =
          [
            {
              directory = "projects";
              method = "symlink";
            }
          ]
          # dconf directories are not owned by user
          ++ lib.optionals config.programs.dconf.enable [
            ".cache/dconf"
            ".config/dconf"
          ]
          ++ cfg.home.directories
          ++ persistCfg.home.directories;
      };
    };
  };
}
