{ lib, ... }@top:
{
  flake.modules.nixos.host_framework =
    { pkgs, ... }:
    {
      imports = with top.config.flake.modules.nixos; [
        gui
        wm

        programs_freecad
        # programs_helix
        # programs_orca-slicer
        # programs_obs-studio
        programs_path-of-building
        # programs_path-of-exile
        # programs_steam
        # programs_subtitles
        # programs_vlc
        programs_wallfacer
        programs_zed-editor
        # programs_zoom

        hardware_amdgpu
        hardware_bluetooth
        # hardware_qmk
        hardware_laptop

        # services_bittorrent
        services_docker
        # services_syncoid
        services_virtualisation

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
              width = 2880;
              height = 1920;
              # 60.001 for 60 fps
              refreshRate = "120.000";
              scale = 1.5;
              vrr = true;
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
          btop.settings = {
            custom_gpu_name0 = "AMD Radeon 780M";
          };
        };

        # don't blind me on startup
        startup = [
          {
            spawn = [
              (lib.getExe pkgs.brightnessctl)
              "s"
              "20%"
            ];
          }
        ];
      };

      networking.hostId = "abb4d116"; # required for zfs

      hardware.framework.laptop13.audioEnhancement.enable = true;

      # touchpad support
      services.libinput.enable = true;

      # disable thumbprint reader
      services.fprintd.enable = false;
    };
}
