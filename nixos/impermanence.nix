{
  config,
  user,
  lib,
  ...
}: let
  cfg = config.iynaix.persist;
in {
  config = lib.mkIf config.iynaix.zfs.enable {
    # root / home filesystem is destroyed and rebuilt on every boot:
    # https://grahamc.com/blog/erase-your-darlings
    boot.initrd.postDeviceCommands = lib.mkAfter (lib.concatStringsSep "\n" [
      (lib.optionalString
        (!cfg.tmpfs.root)
        "zfs rollback -r zroot/local/root@blank")
      # (lib.optionalString
      #   (!cfg.tmpfs.home)
      #   "zfs rollback -r zroot/local/home@blank")
    ]);

    # replace root and /or home filesystems with tmpfs
    fileSystems."/" = lib.mkIf cfg.tmpfs.root (lib.mkForce {
      device = "none";
      fsType = "tmpfs";
      options = ["defaults" "size=3G" "mode=755"];
    });
    fileSystems."/home" = lib.mkIf cfg.tmpfs.home (lib.mkForce {
      device = "none";
      fsType = "tmpfs";
      options = ["defaults" "size=5G" "mode=755"];
    });

    fileSystems."/persist".neededForBoot = true;

    # persisting user passwords
    # https://reddit.com/r/NixOS/comments/o1er2p/tmpfs_as_root_but_without_hardcoding_your/h22f1b9/

    users.mutableUsers = false;
    # create a password with for root and $user with:
    # mkpasswd -m sha-512 'PASSWORD' | sudo tee -a /persist/etc/shadow/root
    users.users.root.passwordFile = "/persist/etc/shadow/root";
    users.users.${user}.passwordFile = "/persist/etc/shadow/${user}";

    # persist files on root filesystem
    environment.persistence."/persist" = {
      hideMounts = true;
      files = ["/etc/machine-id"] ++ cfg.root.files;
      directories = cfg.root.directories;

      # persist for home directory
      users.${user} = {
        files = cfg.home.files;
        directories =
          [
            # TODO: reference projects on another dataset?
            "projects"
          ]
          ++ cfg.home.directories;
      };
    };

    # .Xauthority must be handled specially via a symlink as the
    # bind mount is owned by root
    systemd.tmpfiles.rules = [
      "L+ /home/${user}/.Xauthority - ${user} users - /persist/home/${user}/.Xauthority"
    ];
  };
}
