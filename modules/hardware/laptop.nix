topLevel: {
  flake.nixosModules.laptop = {
    imports = with topLevel.config.flake.nixosModules; [
      backlight
      battery
      keyd
      wifi
    ];
  };
}
