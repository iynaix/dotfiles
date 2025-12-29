topLevel: {
  flake.nixosModules.laptop = {
    imports = with topLevel.config.flake.nixosModules; [
      backlight
      bluetooth
      keyd
      wifi
    ];

    services.upower.enable = true;
  };
}
