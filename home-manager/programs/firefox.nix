{
  inputs,
  pkgs,
  user,
  ...
}:
{
  programs = {
    # use firefox dev edition
    firefox = {
      enable = true;
      package = pkgs.firefox-devedition-bin.overrideAttrs (o: {
        # unable to move .mozilla directory to XDG_CONFIG_HOME
        # as the mozilla path is hardcoded within home-manager

        # resolvable by configPath option in PR:
        # https://github.com/nix-community/home-manager/pull/5128

        # --set 'HOME' '${config.xdg.configHome}' \

        # launch firefox with user profile
        buildCommand =
          o.buildCommand
          + ''
            wrapProgram "$executablePath" \
              --append-flags "--name firefox -P ${user}"
          '';
      });

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

  wayland.windowManager.hyprland.settings = {
    # do not idle while watching videos
    windowrule = [ "idleinhibit fullscreen,firefox-aurora" ];
  };

  custom.persist = {
    home.directories = [
      ".cache/mozilla"
      ".mozilla"
    ];
  };
}
