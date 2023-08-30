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
      device = "none";
      fsType = "tmpfs";
      options = ["defaults" "size=3G" "mode=755"];
    });
    fileSystems."/home/${user}" = lib.mkIf (cfg.tmpfs && cfg.erase.home) (lib.mkForce {
      device = "none";
      fsType = "tmpfs";
      options = ["defaults" "size=5G" "mode=777"];
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

    # https://discourse.nixos.org/t/users-users-name-createhome-not-creating-home-directory/30779/2
    # systemd.services = {
    #   safemcsimw = {
    #     script = ''
    #       chown ${user}:users /home/${user} && chmod 700 /home/${user}
    #     '';
    #     wantedBy = ["multi-user.target"];
    #   };
    # };

    # setup persistence for home manager
    programs.fuse.userAllowOther = true;
    home-manager.users.${user} = {
      systemd.user.startServices = true;
      home.persistence."/persist/home/${user}" = let
        hmCfg = config.home-manager.users.${user}.iynaix.persist;
      in {
        allowOther = true;
        removePrefixDirectory = false;

        files = [".Xauthority"] ++ cfg.home.files ++ hmCfg.home.files;
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
          ++ hmCfg.home.directories;
      };
    };
  };
}
