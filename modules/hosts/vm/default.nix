topLevel: {
  flake.nixosModules.host-vm =
    { lib, pkgs, ... }:
    {
      imports = with topLevel.config.flake.nixosModules; [
        gui
        wm

        ### programs
        # deadbeef
        # freecad
        # helix
        # orca-slicer
        # obs-studio
        # path-of-building
        # path-of-exile
        # steam
        # vlc
        # wallfacer
        # zoom

        ### hardware
        # bluetooth
        # qmk
        # laptop

        ### services
        # bittorrent
        # docker
        # syncoid
        # virtualisation
      ];

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
        wm = "plasma";
      };

      boot.zfs.requestEncryptionCredentials = lib.mkForce false;

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
          ExecStart = "${lib.getExe' pkgs.spice-vdagent "spice-vdagent"} -x";
        };
        unitConfig = {
          ConditionVirtualization = "vm";
          Description = "Spice guest session agent";
          After = [ "graphical-session-pre.target" ];
          PartOf = [ "graphical-session.target" ];
        };
      };
    };
}
