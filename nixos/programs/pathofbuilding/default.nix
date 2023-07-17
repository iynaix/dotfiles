{
  pkgs,
  user,
  lib,
  config,
  ...
}: let
  cfg = config.iynaix.pathofbuilding;
in {
  options.iynaix.pathofbuilding = {
    enable = lib.mkEnableOption "pathofbuilding" // {default = true;};
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${user} = {
      home.packages = [pkgs.path-of-building];
    };

    iynaix.persist.home.directories = [
      ".local/share/pobfrontend"
    ];

    nixpkgs.overlays = [
      (self: super: {
        # add icon and .desktop file
        path-of-building = super.path-of-building.overrideAttrs (oldAttrs: rec {
          installPhase =
            oldAttrs.installPhase
            + ''
              mkdir -p $out/share/pixmaps
              cp ${./PathOfBuilding-logo.png} $out/share/pixmaps/PathOfBuilding.png
              cp ${./PathOfBuilding-logo.svg} $out/share/pixmaps/PathOfBuilding.svg
              ln -sv "${desktopItem}/share/applications" $out/share
            '';

          desktopItem = super.makeDesktopItem {
            name = "Path of Building";
            desktopName = "Path of Building";
            comment = "Offline build planner for Path of Exile";
            exec = "pobfrontend %U";
            terminal = false;
            type = "Application";
            icon = "PathOfBuilding";
            categories = ["Game"];
            keywords = ["poe" "pob" "pobc" "path" "exile"];
            mimeTypes = ["x-scheme-handler/pob"];
          };
        });
      })
    ];
  };
}
