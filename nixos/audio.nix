{ pkgs, ... }:
{
  # setup pipewire for audio
  security.rtkit.enable = true;
  services = {
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    pulseaudio.enable = false;
  };

  environment.systemPackages = with pkgs; [ pwvucontrol ];
}
