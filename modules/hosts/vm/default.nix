{ lib, ... }@top:
{
  flake.nixosModules.host_vm =
    { pkgs, ... }:
    {
      imports = with top.config.flake.nixosModules; [
        gui
        wm

        # programs_freecad
        # programs_helix
        # programs_orca-slicer
        # programs_obs-studio
        # programs_path-of-building
        # programs_path-of-exile
        # programs_steam
        # programs_subtitles
        # programs_vlc
        # programs_wallfacer
        # programs_zed-editor
        # programs_zoom

        # programs_amdgpu
        # programs_qmk
        # programs_laptop

        # services_bittorrent
        # services_docker
        # services_syncoid
        # services_virtualisation
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
