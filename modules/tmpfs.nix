{ config, pkgs, user, lib, inputs, ... }:
let
  cfg = config.iynaix.persist.tmpfs;
in
{
  options.iynaix.persist.tmpfs = {
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

  config = {
    fileSystems."/" = lib.mkIf cfg.root (lib.mkForce {
      device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "size=3G" "mode=755" ];
    });

    fileSystems."/home" = lib.mkIf cfg.home (lib.mkForce {
      device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "size=5G" "mode=755" ];
    });
  };
}
