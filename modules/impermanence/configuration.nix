{ config, pkgs, user, host, ... }:

{
  # root filesystem is destroyed and rebuilt on every boot:
  # https://grahamc.com/blog/erase-your-darlings
  boot.initrd.postDeviceCommands = lib.mkAfter lib.concatStringsSep "\n" [
    "zfs rollback -r zroot/local/root@blank"
    # impermanent home
    # "zfs rollback -r zroot/safe/home@blank"
  ];
}
