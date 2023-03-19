{ pkgs, host, user, config, lib, ... }:
{
  # setup pipewire for audio
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  hardware.pulseaudio.enable = false;

  environment.systemPackages = with pkgs; [
    pamixer
    pavucontrol
  ];

  iynaix.hyprland.extraBinds = {
    bind = {
      ",XF86AudioLowerVolume" = "exec, pamixer -i 5";
      ",XF86AudioRaiseVolume" = "exec, pamixer -d 5";
      ",XF86AudioMute" = "exec, pamixer -t";
    };
  };
}
