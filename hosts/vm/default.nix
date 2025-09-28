{ lib, pkgs, ... }:
let
  inherit (lib) getExe';
in
{
  custom = {
    hardware = {
      monitors = [
        {
          name = "Virtual-1";
          width = 1920;
          height = 1080;
          workspaces = [
            1
            2
            3
            4
            5
            6
            7
            8
            9
            10
          ];
        }
      ];
    };
    programs = {
      pathofbuilding.enable = false;
    };
    wm = "plasma";
    zfs = {
      encryption = false;
      zed = true;
    };
  };

  networking.hostId = "5f43c101"; # required for zfs

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
      ExecStart = "${getExe' pkgs.spice-vdagent "spice-vdagent"} -x";
    };
    unitConfig = {
      ConditionVirtualization = "vm";
      Description = "Spice guest session agent";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };
  };
}
