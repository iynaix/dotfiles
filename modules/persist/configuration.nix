{ config, pkgs, user, host, lib, inputs, ... }: {
  options.iynaix.persist = {
    root = {
      directories = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Directories to persist in root filesystem";
      };
      files = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Files to persist in root filesystem";
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
    };
  };

  config = {
    # root filesystem is destroyed and rebuilt on every boot:
    # https://grahamc.com/blog/erase-your-darlings
    boot.initrd.postDeviceCommands = lib.mkAfter (lib.concatStringsSep "\n" [
      "zfs rollback -r zroot/local/root@blank"
      # impermanent home
      # "zfs rollback -r zroot/safe/home@blank"
    ]);

    fileSystems."/persist".neededForBoot = true;

    # persisting user passwords
    # https://reddit.com/r/NixOS/comments/o1er2p/tmpfs_as_root_but_without_hardcoding_your/h22f1b9/

    users.mutableUsers = false;
    users.users.root.passwordFile = "/persist/passwords/root";
    users.users.${user}.passwordFile = "/persist/passwords/${user}";

    security.sudo.extraConfig = "Defaults lecture=never"; # shut sudo up

    # persist files on root filesystem
    environment.persistence."/persist" = {
      hideMounts = true;
      files = [ "/etc/machine-id" ] ++ config.iynaix.persist.root.files;
      directories = config.iynaix.persist.root.directories;

      # persist for home directory
      users.${user} = {
        files = [ ".local/share/keyrings" ] ++ config.iynaix.persist.home.files;
        directories = config.iynaix.persist.home.directories;
      };
    };
  };
}
