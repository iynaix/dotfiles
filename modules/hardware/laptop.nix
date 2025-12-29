topLevel: {
  flake.nixosModules.laptop = {
    imports = with topLevel.config.flake.nixosModules; [
      backlight
      bluetooth
      keyd
      wifi
    ];

    # required for noctalia's battery module
    services.upower.enable = true;
  };
}
