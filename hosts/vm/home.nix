{config, ...}: let
  displayCfg = config.iynaix.displays;
in {
  iynaix = {
    displays = {
      monitor1 = "Virtual-1";
    };

    pathofbuilding.enable = false;

    # wayland settings
    hyprland = {
      enable = true;
      monitors = "monitor = ${displayCfg.monitor1}, 1920x1200,0x0,1";
    };
  };
}
