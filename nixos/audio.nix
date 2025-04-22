{
  host,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  config = {
    # setup pipewire for audio
    security.rtkit.enable = true;
    services = {
      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;

        extraConfig = {
          pipewire = {
            switch-on-connect = {
              "pulse.cmd" = [
                {
                  cmd = "load-module";
                  args = [ "module-switch-on-connect" ];
                }
              ];
            };
          };
        };

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
      };
    };

    environment.systemPackages = with pkgs; [ pwvucontrol ];

    # change waybar icon for headphones / speakers
    hm.custom.waybar.config = mkIf (host == "desktop") {
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
}
