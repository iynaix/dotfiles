{
  config,
  isVm,
  lib,
  pkgs,
  user,
  ...
}:
let
  inherit (lib) mkIf mkMerge;
in
{
  custom = {
    specialisation = {
      niri.enable = true;
      hyprland.enable = true;
      mango.enable = false;
    };

    hardware = {
      hdds.enable = true;
      nvidia.enable = true;
      monitors = [
        {
          name = "DP-2";
          width = 3440;
          height = 1440;
          # niri / mango wants this to be exact down to the decimals
          refreshRate = if config.custom.wm == "hyprland" then "144" else "174.963";
          vrr = false;
          positionX = 1440;
          positionY = 1080;
          workspaces = [
            1
            2
            3
            4
            5
          ];
          extraHyprlandConfig = {
            supports_hdr = 1;
            bitdepth = 10;
          };
        }
        {
          name = "DP-1";
          width = 2560;
          height = 1440;
          positionX = 0;
          positionY = 728;
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
          positionX = 1754;
          positionY = 0;
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
        #   positionX = 4880;
        #   positionY = 1080;
        #   scale = 1.5666666666666666; # 47/30
        #   transform = 3;
        #   workspaces = [
        #     8
        #     10
        #   ];
        #   defaultWorkspace = 10;
        # }
      ];
      qmk.enable = true;
    };
    lock.enable = false;
    zfs.encryption = false;

    programs = {
      deadbeef.enable = true;
      distrobox.enable = true;
      hyprland = {
        qtile = false;
      };
      freecad.enable = true;
      hyprnstack.enable = true;
      niri.blur.enable = false;
      obs-studio.enable = true;
      orca-slicer.enable = true;
      pathofbuilding.enable = true;
      rclip.enable = true;
      vlc.enable = true;
      wallfacer.enable = true;
      wallpaper-tools.enable = true;

      # wallust.colorscheme = "tokyo-night";

      # change waybar icon for headphones / speakers
      waybar.config = {
        pulseaudio = {
          # show DAC as headphones
          format-icons = {
            "alsa_output.usb-SAVITECH_Bravo-X_USB_Audio-01.analog-stereo" = "󰋋";
            "alsa_output.usb-Yoyodyne_Consulting_ODAC-revB-01.analog-stereo" = "󰋋";
            "alsa_output.usb-Kanto_Audio_ORA_by_Kanto_20240130-00.analog-stereo" = "󰓃";
          };
        };
      };
    };

    services = {
      bittorrent.enable = true;
      syncoid.enable = true;
      vercel.enable = true;
      virtualization.enable = true;
    };
  };

  services = {
    displayManager.autoLogin.user = user;

    pipewire = {
      # enable soft-mixer to fix global volume control for kanto?
      # wireplumber.extraConfig = mkIf (host == "desktop") {
      #   "alsa-soft-mixer"."monitor.alsa.rules" = [
      #     {
      #       actions.update-props."api.alsa.soft-mixer" = true;
      #       matches = [
      #         {
      #           "device.name" = "alsa_output.usb-Kanto_Audio_ORA_by_Kanto_20240130-00.analog-stereo";
      #           "device.name" = "~alsa_card.*";
      #         }
      #       ];
      #     }
      #   ];
      # };

      # wireplumber.configPackages = [
      #   # prefer DAC over speakers
      #   (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/90-custom-audio-priority.conf" ''
      #     monitor.alsa.rules = [
      #       {
      #         matches = [
      #           {
      #             node.name = "alsa_output.usb-Yoyodyne_Consulting_ODAC-revB-01.analog-stereo"
      #           }
      #         ]
      #         actions = {
      #           update-props = {
      #             priority.driver = 2000
      #             priority.session = 2000
      #           }
      #         }
      #       }
      #     ]
      #   '')
      # ];
    };
  };

  networking = mkMerge [
    { hostId = "89eaa833"; } # required for zfs
    (mkIf (!isVm) {
      interfaces.enp5s0.wakeOnLan.enable = true;
      # open ports for devices on the local network
      firewall.extraCommands = # sh
        ''
          iptables -A nixos-fw -p tcp --source 192.168.1.0/24 -j nixos-fw-accept
        '';
    })
  ];

  # fix no login prompts in ttys, virtual tty are being redirected to mobo video output
  # https://unix.stackexchange.com/a/253401
  boot.blacklistedKernelModules = [ "amdgpu" ];

  # enable flirc usb ir receiver
  hardware.flirc.enable = false;
  environment.systemPackages = mkIf config.hardware.flirc.enable [ pkgs.flirc ];

  # fix intel i225-v ethernet dying due to power management
  # https://reddit.com/r/buildapc/comments/xypn1m/network_card_intel_ethernet_controller_i225v_igc/
  # boot.kernelParams = ["pcie_port_pm=off" "pcie_aspm.policy=performance"];
}
