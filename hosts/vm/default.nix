{ lib, pkgs, ... }:
{
  custom = {
    plasma.enable = true;
    zfs.encryption = false;
  };

  networking.hostId = "5f43c101"; # required for zfs

  # doesn't work with by-id
  boot.zfs.devNodes = "/dev/disk/by-partuuid";

  # enable clipboard and file sharing
  services = {
    qemuGuest.enable = true;
    spice-vdagentd.enable = true;
    spice-webdavd.enable = true;
  };

  # fix for spice-vdagentd not starting in wms
  systemd.user.services.spice-agent = {
    enable = true;
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${lib.getExe' pkgs.spice-vdagent "spice-vdagent"} -x";
    };
    unitConfig = {
      ConditionVirtualization = "vm";
      Description = "Spice guest session agent";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };
  };
}
