{ config, pkgs, user, host, lib, inputs, ... }: {
  options.iynaix.persist = {
    tmpfs = {
      root = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable tmpfs for /";
      };
      home = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable tmpfs for /home";
      };
    };
  };

  config = {
    fileSystems."/" = lib.mkIf config.iynaix.persist.tmpfs.root (lib.mkForce {
      device = "none";
      fsType = "zfs";
      options = [ "defaults" "size=3G" "mode=755" ];
    });

    fileSystems."/home" = lib.mkIf config.iynaix.persist.tmpfs.home (lib.mkForce {
      device = "none";
      fsType = "zfs";
      options = [ "defaults" "size=5G" "mode=755" ];
    });
  };
}
