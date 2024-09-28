{
  config,
  inputs,
  pkgs,
  user,
  ...
}:
{
  programs = {
    # use firefox dev edition
    firefox = rec {
      enable = true;
      package = pkgs.firefox-devedition-bin.overrideAttrs (o: {
        # launch firefox with user profile
        buildCommand =
          o.buildCommand
          + ''
            wrapProgram "$executablePath" \
              --set 'HOME' '${config.xdg.configHome}' \
              --append-flags "--name firefox -P ${user}"
          '';
      });

      vendorPath = ".config/.mozilla";
      configPath = "${vendorPath}/firefox";

      profiles.${user} = {
        # TODO: define keyword searches here?
        # search.engines = [ ];

        isDefault = true;
        settings = {
          "browser.display.use_document_fonts" = 0;
          "browser.ctrlTab.sortByRecentlyUsed" = false;
          "browser.theme.toolbar-theme" = 0;
          "general.autoScroll" = true;
        };

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

  wayland.windowManager.hyprland.settings = {
    # do not idle while watching videos
    windowrule = [ "idleinhibit fullscreen,firefox-aurora" ];
  };

  custom.persist = {
    home.directories = [
      ".cache/mozilla"
      ".config/.mozilla"
    ];
  };
}
