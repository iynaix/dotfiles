{
  config,
  user,
  lib,
  ...
}: let
  cfg = config.iynaix-nixos.persist;
  hmCfg = config.home-manager.users.${user}.iynaix.persist;
in {
  config = lib.mkIf config.iynaix-nixos.zfs.enable {
    # root / home filesystem is destroyed and rebuilt on every boot:
    # https://grahamc.com/blog/erase-your-darlings
    boot.initrd.postDeviceCommands = lib.mkAfter (lib.concatStringsSep "\n" [
      (lib.optionalString (cfg.blank.root) "zfs rollback -r zroot/local/root@blank")
      (lib.optionalString (cfg.blank.home) "zfs rollback -r zroot/safe/home@blank")
    ]);

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
      inherit (cfg.root) files directories;

      # persist for home directory
      users.${user} = {
        files = cfg.home.files ++ hmCfg.home.files;
        directories = ["projects"] ++ cfg.home.directories ++ hmCfg.home.directories;
      };
    };

    # .Xauthority must be handled specially via a symlink as the
    # bind mount is owned by root
    systemd.tmpfiles.rules = [
      "L+ /home/${user}/.Xauthority - ${user} users - /persist/home/${user}/.Xauthority"
    ];
  };
}
