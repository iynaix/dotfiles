{pkgs, ...}: {
  iynaix-nixos = {
    hyprland.enable = true;
    zfs.encryption = false;
  };

  networking.hostId = "5f43c101"; # required for zfs

  # doesn't work with by-id
  boot.zfs.devNodes = "/dev/disk/by-partuuid";

  # enable clipboard and file sharing
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;
  services.spice-webdavd.enable = true;

  # fix for spice-vdagentd not starting in wms
  systemd.user.services.spice-agent = {
    enable = true;
    wantedBy = ["graphical-session.target"];
    serviceConfig = {
      ExecStart = "${pkgs.spice-vdagent}/bin/spice-vdagent -x";
    };
    unitConfig = {
      ConditionVirtualization = "vm";
      Description = "Spice guest session agent";
      After = ["graphical-session-pre.target"];
      PartOf = ["graphical-session.target"];
    };
  };
}
