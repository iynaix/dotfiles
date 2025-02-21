{
  config,
  inputs,
  host,
  lib,
  pkgs,
  user,
  ...
}:
let
  inherit (lib) concatStringsSep mkIf optionals;
in
mkIf (!config.custom.headless) {
  programs.firefox = rec {
    enable = true;
    # use firefox dev edition
    package = pkgs.firefox-devedition.overrideAttrs (o: {
      # launch firefox with user profile
      buildCommand =
        o.buildCommand
        + ''
          wrapProgram "$out/bin/firefox-devedition" \
            --set 'HOME' '${config.xdg.configHome}' \
            --append-flags "${
              concatStringsSep " " (
                [
                  "--name firefox"
                  # load user firefox profile
                  "-P ${user}"
                  # start with urls:
                  "https://discordapp.com/channels/@me"
                ]
                ++ optionals (host == "desktop") [
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

  custom.persist = {
    home.directories = [
      ".cache/mozilla"
      ".config/.mozilla"
    ];
  };
}
