top: {
  flake.nixosModules.hardware_laptop = {
    imports = with top.config.flake.nixosModules; [
      hardware_backlight
      hardware_bluetooth
      hardware_keyd
      hardware_wifi
    ];

    # scrolling is nice for laptop with a smaller screen
    services.displayManager.defaultSession = "niri";

    # required for noctalia's battery module
    services.upower.enable = true;
  };
}
