{
  config,
  host,
  lib,
  pkgs,
  user,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    mkIf
    optionals
    ;
  configPath = ".config/.librewolf";
in
mkIf (config.custom.wm != "tty") {
  programs.firefox = {
    enable = true;
    package = pkgs.librewolf.overrideAttrs (o: {
      # launch librewolf with user profile
      buildCommand = o.buildCommand + ''
        wrapProgram "$out/bin/librewolf" \
          --set 'HOME' '${config.hj.xdg.config.directory}' \
          --append-flags "${
            concatStringsSep " " (
              [
                # load librewolf profile with same name as user
                "--profile ${config.hj.directory}/${configPath}/${user}"
              ]
              ++ [
                # launch with the following urls:
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

    policies = {
      Extensions = {
        Install = [
          "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/"
          "https://addons.mozilla.org/firefox/downloads/latest/darkreader/"
          "https://addons.mozilla.org/firefox/downloads/latest/screenshot-capture-annotate/"
          "https://addons.mozilla.org/firefox/downloads/latest/sponsorblock/"
          "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/"
        ];
        # extension IOs can be obtained after installation by going to about:support
        Locked = [
          "{446900e4-71c2-419f-a6a7-df9c091e268b}" # bitwarden
          "addon@darkreader.org"
          "jid0-GXjLLfbCoAx0LcltEdFrEkQdQPI@jetpack" # screenshot-capture-annotate
          "sponsorBlocker@ajay.app"
          "uBlock0@raymondhill.net"
        ];
        ExtensionSettings = {
          # bitwarden
          "{446900e4-71c2-419f-a6a7-df9c091e268b}".private_browsing = true;
          "addon@darkreader.org".private_browsing = true;
          # screenshot-capture-annotate
          "jid0-GXjLLfbCoAx0LcltEdFrEkQdQPI@jetpack".private_browsing = true;
          "sponsorBlocker@ajay.app".private_browsing = true;
          "uBlock0@raymondhill.net".private_browsing = true;
        };
      };
    };

    # inherit configPath;

    # TODO: define keyword searches here?
    # search.engines = [ ];

    preferences = {
      "browser.download.dir" = "${config.hj.directory}/Downloads";
      "browser.download.useDownloadDir" = false;
      "privacy.clearOnShutdown_v2.cache" = false;
      "privacy.clearOnShutdown_v2.cookiesAndStorage" = false;
      "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
    };

    #   userChrome = # css
    #     ''
    #       /* remove useless urlbar padding */
    #       #customizableui-special-spring1 { display:none }
    #       #customizableui-special-spring2 { display:none }

    #       /* remove all tabs button and window controls */
    #       #alltabs-button { display:none }
    #       .titlebar-spacer { display:none }
    #       .titlebar-buttonbox-container { display:none }
    #     '';
    # };
  };

  custom.persist = {
    home.directories = [
      ".cache/librewolf"
      configPath
    ];
  };
}
