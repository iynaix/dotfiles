{ lib, ... }@top:
{
  flake.modules.nixos.host_xps =
    { pkgs, ... }:
    {
      imports = with top.config.flake.modules.nixos; [
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

        # hardware_amdgpu
        # hardware_qmk
        hardware_laptop

        # services_bittorrent
        # services_docker
        # services_syncoid
        # services_virtualisation

        # specialisations_tty
        # specialisations_niri
        # specialisations_hyprland
        # specialisations_mango
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
