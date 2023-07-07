{
  config,
  pkgs,
  user,
  lib,
  host,
  ...
}: let
  displayCfg = config.iynaix.displays;
in {
  imports = [./hardware.nix];

  config = {
    iynaix = {
      displays.monitor1 = "Virtual-1";

      pathofbuilding.enable = false;

      # wayland settings
      hyprland = {
        enable = true;
        monitors = "monitor = ${displayCfg.monitor1}, 1920x1200,0x0,1";
      };

      # persist.tmpfs.root = true;
      # persist.tmpfs.home = true;
    };

    environment.sessionVariables = lib.mkIf config.iynaix.hyprland.enable {
      WLR_RENDERER_ALLOW_SOFTWARE = "1";
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

    home-manager.users.${user} = {};
  };
}
