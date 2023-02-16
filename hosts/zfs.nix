{ config, pkgs, user, host, ... }:

{
  # options for booting with zfs
  boot.supportedFileSystems = [ "zfs" ];
  boot.zfs.devNodes = "/dev/disk/by-partuuid";

  # root filesystem is destroyed and rebuilt on every boot:
  # https://grahamc.com/blog/erase-your-darlings
  # boot.initrd.postDeviceCommands = lib.mkAfter ''
  #   zfs rollback -r zroot/local/root@blank
  # '';
}
