{
  config,
  user,
  lib,
  ...
}: let
  nixos-cfg = config.iynaix-nixos.persist;
  hm-cfg = config.home-manager.users.${user}.iynaix.persist;
in {
  config = lib.mkIf config.iynaix-nixos.zfs.enable {
    # root / home filesystem is destroyed and rebuilt on every boot:
    # https://grahamc.com/blog/erase-your-darlings
    boot.initrd.postDeviceCommands = lib.mkAfter (lib.concatStringsSep "\n" [
      (lib.optionalString
        (!nixos-cfg.tmpfs.root)
        "zfs rollback -r zroot/local/root@blank")
      (lib.optionalString
        (!nixos-cfg.tmpfs.home)
        "zfs rollback -r zroot/local/home@blank")
    ]);

    # replace root and /or home filesystems with tmpfs
    fileSystems."/" = lib.mkIf nixos-cfg.tmpfs.root (lib.mkForce {
      device = "none";
      fsType = "tmpfs";
      options = ["defaults" "size=3G" "mode=755"];
    });
    fileSystems."/home" = lib.mkIf nixos-cfg.tmpfs.home (lib.mkForce {
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
      files = ["/etc/machine-id"] ++ nixos-cfg.root.files;
      directories = nixos-cfg.root.directories;

      # persist for home directory
      users.${user} = {
        files = nixos-cfg.home.files ++ hm-cfg.home.files;
        directories = ["projects"] ++ nixos-cfg.home.directories ++ hm-cfg.home.directories;
      };
    };

    # .Xauthority must be handled specially via a symlink as the
    # bind mount is owned by root
    systemd.tmpfiles.rules = [
      "L+ /home/${user}/.Xauthority - ${user} users - /persist/home/${user}/.Xauthority"
    ];
  };
}
