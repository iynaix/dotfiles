{
  config,
  inputs,
  host,
  lib,
  pkgs,
  user,
  ...
}:
lib.mkIf (!config.custom.headless) {
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
              --append-flags "${
                lib.concatStringsSep " " (
                  [
                    "--name firefox"
                    # load user firefox profile
                    "-P ${user}"
                    # start with urls:
                    "https://discordapp.com/channels/@me"
                  ]
                  ++ lib.optionals (host == "desktop") [
                    "https://web.whatsapp.com" # requires access via local network
                    "http://localhost:9091" # transmission
                  ]
                )
              }"
          '';
      });

      vendorPath = ".config/.mozilla";
      configPath = "${vendorPath}/firefox";

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
      ".config/.mozilla"
    ];
  };
}
