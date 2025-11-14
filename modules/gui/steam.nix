{
  flake.nixosModules.steam = {
    programs.steam = {
      enable = true;
    };

    custom.persist = {
      home.directories = [
        ".steam"
        ".local/share/applications" # desktop files from steam
        ".local/share/icons/hicolor" # icons from steam
        ".local/share/Steam"
      ];
    };
  };
}
