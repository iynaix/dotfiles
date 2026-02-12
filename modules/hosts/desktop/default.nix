{ lib, ... }@topLevel:
{
  flake.nixosModules.host-desktop =
    { config, pkgs, ... }:
    let
      inherit (config.custom.constants) isVm user;
      # fetch wallpapers from pixiv for user
      pixiv = pkgs.writeShellApplication {
        name = "pixiv";
        runtimeInputs = [ pkgs.custom.direnv-cargo-run ];
        text = /* sh */ ''
          direnv-cargo-run "/persist${config.hj.directory}/projects/pixiv" "$@"
        '';
      };

      toggle-speaker = pkgs.writeShellApplication {
        name = "toggle-speaker";
        text = /* sh */ ''
          # Device names
          KANTO="ORA"
          TOPPING="DX5"

          # Get current default sink with asterisk
          current_line=$(wpctl status | grep -A 20 "Sinks:" | grep "\*")

          if [ -z "$current_line" ]; then
              echo "Could not determine current audio sink"
              exit 1
          fi

          # Determine which device to switch to
          if echo "$current_line" | grep -q "Kanto"; then
              target_device="$TOPPING"
              friendly_name="Headphones"
          elif echo "$current_line" | grep -q "DX5"; then
              target_device="$KANTO"
              friendly_name="Speakers"
          else
              echo "Current device is neither Kanto nor Topping, defaulting to KANTO"
              target_device="$KANTO"
              friendly_name="Speakers"
          fi

          echo "TARGET DEVICE: $target_device"

          # Get the sink ID for the target device
          sink_id=$(wpctl status | grep -A 20 "Sinks:" | grep "$target_device" | awk '{print $2}' | grep -oP '[0-9]+' | head -1)

          if [ -z "$sink_id" ]; then
              noctalia-ipc toast send "{\"title\": \"Unable to switch to $friendly_name\", \"type\": \"warning\"}"
              exit 1
          fi

          # Set as default
          wpctl set-default "$sink_id"

          noctalia-ipc toast send "{\"title\": \"Switched audio output to $friendly_name\"}"
        '';
      };
    in
    {
      imports = with topLevel.config.flake.nixosModules; [
        gui
        wm

        ### programs
        # deadbeef  # swift is currently broken
        freecad
        # helix
        orca-slicer
        obs-studio
        path-of-building
        path-of-exile
        steam
        subtitles
        vlc
        wallfacer
        # zoom

        ### hardware
        amdgpu
        qmk
        # laptop

        ### services
        bittorrent
        docker
        syncoid
        virtualisation
      ];

      custom = {
        specialisation = {
          niri.enable = true;
          hyprland.enable = true;
          mango.enable = true;
        };

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
              extraHyprlandConfig = {
                # supports_hdr = 1;
                bitdepth = 10;
              };
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
          hyprnstack.enable = true;

          btop.extraSettings = {
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
        displayManager = {
          autoLogin.user = user;
          defaultSession = "niri";
        };

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
        toggle-speaker
      ];
    };
}
