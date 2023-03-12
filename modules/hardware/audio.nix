{ pkgs, host, user, config, ... }:
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

  home-manager.users.${user} = {
    services = {
      sxhkd.keybindings =
        {
          XF86AudioLowerVolume = "pamixer -i 5";
          XF86AudioRaiseVolume = "pamixer -d 5";
          XF86AudioMute = "pamixer -t";
        };
    };
  };

  iynaix.hyprland.extraBinds = {
    bind = {
      XF86AudioLowerVolume = "pamixer -i 5";
      XF86AudioRaiseVolume = "pamixer -d 5";
      XF86AudioMute = "pamixer -t";
    };
  };
}
