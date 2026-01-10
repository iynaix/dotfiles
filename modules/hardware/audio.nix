{ lib, ... }:
{
  flake.nixosModules.core =
    { host, pkgs, ... }:
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
      };

      environment.systemPackages = with pkgs; [
        pamixer
        pavucontrol
      ];

      custom.programs.noctalia.settingsReducers = [
        # toggle-speaker is only for desktop
        (
          prev:
          lib.recursiveUpdate prev {
            bar.widgets.right = map (
              widget:
              if widget.id == "Volume" then
                widget
                // {
                  middleClickCommand = if host == "desktop" then "toggle-speaker" else "pwvucontrol || pavucontrol";
                }
              else
                widget
            ) prev.bar.widgets.right;
          }
        )
      ];

      custom.persist = {
        home.directories = [
          ".local/state/wireplumber"
        ];
      };
    };
}
