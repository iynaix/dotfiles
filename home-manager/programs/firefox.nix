{
  inputs,
  lib,
  pkgs,
  user,
  ...
}: let
  firefoxPkg = pkgs.firefox-devedition-bin;
in {
  programs = {
    # firefox dev edition
    firefox = {
      enable = true;
      package = firefoxPkg;

      profiles.${user} = {
        # TODO: define keyword searches here?
        # search.engines = [ ];

        extensions = with inputs.firefox-addons.packages.${pkgs.system}; [
          bitwarden
          darkreader
          screenshot-capture-annotate
          sponsorblock
          ublock-origin
        ];
      };
    };
  };

  # overwrite desktop entry with user profile
  xdg.desktopEntries.firefox-developer-edition = {
    name = "Firefox Developer Edition";
    genericName = "Web Browser";
    exec = "${lib.getExe firefoxPkg} --name firefox -P ${user} %U";
    icon = "${firefoxPkg}/share/icons/hicolor/128x128/apps/firefox.png";
    categories = ["Network" "WebBrowser"];
  };

  custom.persist = {
    home.directories = [
      ".cache/mozilla"
      ".mozilla"
    ];
  };
}
