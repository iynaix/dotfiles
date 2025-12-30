{
  # for calendar events
  flake.nixosModules.wm = {
    services.gnome.evolution-data-server.enable = true;

    custom.persist = {
      home = {
        directories = [
          ".config/evolution"
        ];

        cache.directories = [
          ".cache/evolution"
        ];
      };
    };
  };
}
