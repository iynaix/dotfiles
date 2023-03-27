{
  pkgs,
  host,
  user,
  lib,
  ...
}: let
  hasDac = host == "desktop";
  reset-dac = pkgs.writeShellScriptBin "reset-dac" ''
    sudo ${pkgs.usb-modeswitch}/bin/usb_modeswitch -v 0x262a -p 0x1048 --reset-usb
  '';
in {
  config = {
    # setup pipewire for audio
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    hardware.pulseaudio.enable = false;

    environment.systemPackages = with pkgs;
      [
        pamixer
        pavucontrol
      ]
      ++ (lib.optional hasDac reset-dac);

    security.sudo.extraRules = lib.mkIf hasDac [
      {
        users = [user];
        commands = [
          {
            command = "${pkgs.usb-modeswitch}/bin/usb_modeswitch";
            options = ["NOPASSWD"];
          }
        ];
      }
    ];

    iynaix.hyprland.extraBinds = {
      bind = {
        ",XF86AudioLowerVolume" = "exec, pamixer -i 5";
        ",XF86AudioRaiseVolume" = "exec, pamixer -d 5";
        ",XF86AudioMute" = "exec, pamixer -t";
      };
    };
  };
}
