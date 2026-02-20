{ lib, ... }@top:
{
  flake.nixosModules.host-xps =
    { pkgs, ... }:
    {
      imports = with top.config.flake.nixosModules; [
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
        # subtitles
        # vlc
        # wallfacer
        # zoom

        ### hardware
        # amdgpu
        # qmk
        laptop

        ### services
        # bittorrent
        # docker
        # syncoid
        # virtualisation

        ### specialisations
        # specialisation-tty
        # specialisation-niri
        # specialisation-hyprland
        # specialisation-mango
      ];

      custom = {
        hardware = {
          monitors = [
            {
              name = "eDP-1";
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
              refreshRate = "59.934";
            }
          ];
        };

        programs = {
          btop.extraSettings = {
            custom_gpu_name0 = "Intel HD Graphics 5500";
          };
        };
      };

      networking.hostId = "17521d0b"; # required for zfs

      # larger runtime directory size to not run out of ram while building
      # https://discourse.nixos.org/t/run-usr-id-is-too-small/4842
      services.logind.settings.Login = {
        RuntimeDirectorySize = "3G";
      };

      # touchpad support
      services.libinput.enable = true;

      security.wrappers = {
        btop = {
          capabilities = "cap_perfmon=+ep";
          group = "wheel";
          owner = "root";
          permissions = "0750";
          source = lib.getExe pkgs.btop;
        };
      };
    };
}
