{ lib, ... }@top:
{
  flake.modules.nixos.host_desktop =
    { config, pkgs, ... }:
    let
      inherit (config.custom.constants) projects isVm;
      # fetch wallpapers from pixiv for user
      pixiv = pkgs.writeShellApplication {
        name = "pixiv";
        runtimeInputs = [ pkgs.custom.direnv-cargo-run ];
        text = /* sh */ ''
          direnv-cargo-run "${projects}/pixiv" "$@"
        '';
      };
    in
    {
      imports = with top.config.flake.modules.nixos; [
        gui
        wm

        programs_freecad
        # programs_helix
        programs_orca-slicer
        programs_obs-studio
        programs_path-of-building
        programs_path-of-exile
        programs_steam
        programs_subtitles
        programs_vlc
        programs_wallfacer
        # programs_zed-editor
        # programs_zoom

        hardware_amdgpu
        hardware_qmk
        # hardware_laptop

        services_bittorrent
        services_docker
        services_syncoid
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
              name = "DP-1";
              width = 3440;
              height = 1440;
              # niri / mango wants this to be exact down to the decimals
              refreshRate = "174.963";
              vrr = false;
              x = 1440;
              y = 1080;
              workspaces = [
                1
                2
                3
                4
                5
              ];
              hdr = false; # toggle to use hdr
            }
            {
              name = "DP-2";
              width = 2560;
              height = 1440;
              x = 0;
              y = 728;
              transform = 1;
              workspaces = [
                6
                7
              ];
              defaultWorkspace = 7;
              refreshRate = "59.951";
            }
            {
              name = "HDMI-A-1";
              width = 3840;
              height = 2160;
              x = 1754;
              y = 0;
              scale = 2.0;
              workspaces = [
                8
                9
                10
              ];
              defaultWorkspace = 9;
              refreshRate = "59.997";
            }
            # {
            #   name = "DP-3";
            #   width = 2256;
            #   height = 1504;
            #   x = 4880;
            #   y = 1080;
            #   scale = 1.5666666666666666; # 47/30
            #   transform = 3;
            #   workspaces = [
            #     8
            #     10
            #   ];
            #   defaultWorkspace = 10;
            # }
          ];
        };
        lock.enable = false;

        programs = {
          btop.settings = {
            custom_gpu_name0 = "AMD Radeon RX 9070XT";
          };
        };

        # disable networkmanager software wifi switch on startup, so noctalia doesn't toggle it back on when syncing state
        startup = [
          {
            spawn = [
              "nmcli"
              "radio"
              "wifi"
              "off"
            ];
          }
        ];
      };

      boot.zfs.requestEncryptionCredentials = lib.mkForce false;

      services = {
        # displayManager.defaultSession = "hyprland";

        pipewire = {
          wireplumber.extraConfig = {
            "99-disable-devices" = {
              "monitor.alsa.rules" = [
                {
                  matches = [
                    { "device.name" = "alsa_card.pci-0000_03_00.1"; }
                    { "device.name" = "alsa_card.usb-Generic_USB_Audio-00"; }
                    { "device.name" = "alsa_card.pci-0000_0f_00.1"; }
                  ];
                  actions = {
                    update-props = {
                      "device.disabled" = true;
                    };
                  };
                }
              ];
            };
          };
        };
      };

      networking = lib.mkMerge [
        { hostId = "89eaa833"; } # required for zfs
        (lib.mkIf (!isVm) {
          interfaces.enp7s0.wakeOnLan.enable = true;
          # open ports for devices on the local network
          firewall.extraCommands = /* sh */ ''
            iptables -A nixos-fw -p tcp --source 192.168.1.0/24 -j nixos-fw-accept
          '';
        })
      ];

      # enable flirc usb ir receiver
      hardware.flirc.enable = false;
      environment.systemPackages = [
        pixiv
      ];
    };
}
