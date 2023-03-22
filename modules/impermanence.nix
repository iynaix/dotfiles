{
  config,
  pkgs,
  user,
  lib,
  inputs,
  ...
}: let
  cfg = config.iynaix.persist;
in {
  imports = [./tmpfs.nix];

  options.iynaix.persist = {
    root = {
      directories = lib.mkOption {
        default = [];
        description = "Directories to persist in root filesystem";
      };
      files = lib.mkOption {
        default = [];
        description = "Files to persist in root filesystem";
      };
    };
    home = {
      directories = lib.mkOption {
        default = [];
        description = "Directories to persist in home directory";
      };
      files = lib.mkOption {
        default = [];
        description = "Files to persist in home directory";
      };
    };
  };

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

    fileSystems."/persist".neededForBoot = true;

    # persisting user passwords
    # https://reddit.com/r/NixOS/comments/o1er2p/tmpfs_as_root_but_without_hardcoding_your/h22f1b9/

    users.mutableUsers = false;
    # create a password with for root and $user with:
    # mkpasswd -m sha-512 'PASSWORD' | sudo tee -a /persist/etc/shadow/root
    users.users.root.passwordFile = "/persist//etc/shadow/root";
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
