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

      extraConfig = {
        pipewire-pulse = {
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
    };
  };

  environment.systemPackages = with pkgs; [ pwvucontrol ];
}
