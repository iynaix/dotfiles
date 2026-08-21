{
  hosts = [ "laptop" ];

  config = {
    # scrolling is nice for laptop with a smaller screen
    services.displayManager.defaultSession = "niri";

    # required for noctalia's battery module
    services.upower.enable = true;
  };
}
