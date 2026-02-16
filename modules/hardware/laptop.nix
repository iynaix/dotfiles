topLevel: {
  flake.nixosModules.laptop = {
    imports = with topLevel.config.flake.nixosModules; [
      backlight
      bluetooth
      keyd
      wifi
    ];

    # scrolling is nice for laptop with a smaller screen
    services.displayManager.defaultSession = "niri";

    # required for noctalia's battery module
    services.upower.enable = true;
  };
}
