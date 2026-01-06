{
  flake.nixosModules.gui =
    {
      inputs,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) getExe;
      # fix chromium based browsers crashing on monitor change:
      # https://github.com/brave/brave-browser/issues/49862
      heliumPkg = inputs.wrappers.lib.wrapPackage {
        inherit pkgs;
        package = pkgs.custom.helium;
        flagSeparator = "=";
      };
    in
    {
      programs.chromium = {
        # NOTE: programs.chromium.enable does not install any package!, it only creates policy files
        enable = true;

        extensions = [
          # uAutoPagerize
          "kdplapeciagkkjoignnkfpbfkebcfbpb"
          # Awesome Screen Recorder & Screenshot
          "nlipoenfbbikpbjkfpfillcgkoblgpmj"
          # Better PathOfExile Trading
          "fhlinfpmdlijegjlpgedcmglkakaghnk"
          # Bitwarden
          "nngceckbapebfimnlniiiahkandclblb"
          # Dark Reader
          "eimadpbcbfnmbkopoojfekhnkhdbieeh"
          # JSON Viewer
          "gbmdgpbipfallnflgajpaliibnhdgobh"
          # Looty
          # "ajfbflclpnpbjkfibijekgcombcgehbi"
          # Old Reddit Redirect
          "dneaehbmnbhcippjikoajpoabadpodje"
          # React Dev Tools
          "fmkadmapgofadopljbjfkapdkoienihi"
          # Reddit Enhancement Suite
          "kbmfpngjjgdllneeigpgjifpgocmfgmb"
          # Return YouTube Dislike
          "gebbhagfogifgggkldgodflihgfeippi"
          # Session Manager
          "mghenlmbmjcpehccoangkdpagbcbkdpc"
          # SponsorBlock for YouTube - Skip Sponsorships
          "mnjggcdmjocbbbhaepdhchncahnbgone"
          # Tokyo Night Storm
          "pgbjifpikialeahbdendkjioeafbmfkn"
          # uBlock Origin (already preinstalled)
          # "cjpalhdlnbpafiamejdnhcphjbkeiagm"
          # Video Speed Controller
          "nffaoalbilbmmfgbnbgppjihopabppdk"
          # YouTube Auto HD + FPS
          "fcphghnknhkimeagdglkljinmpbagone"
          # Youtube-shorts block
          "jiaopdjbehhjgokpphdfgmapkobbnmjp"
        ];
      };

      environment = {
        sessionVariables = {
          DEFAULT_BROWSER = getExe heliumPkg;
          BROWSER = getExe heliumPkg;
        };

        systemPackages = [
          heliumPkg
        ];
      };

      xdg.mime.defaultApplications = {
        "text/html" = "helium.desktop";
        "x-scheme-handler/http" = "helium.desktop";
        "x-scheme-handler/https" = "helium.desktop";
        "x-scheme-handler/about" = "helium.desktop";
        "x-scheme-handler/unknown" = "helium.desktop";
      };

      custom.programs.hyprland.settings.windowrule = [
        # do not idle while watching videos
        "match:class helium, idle_inhibit fullscreen"
        "match:class helium, match:title (.*)(YouTube)(.*), idle_inhibit focus"
        # float save dialogs
        # save as
        "match:initial_class helium, match:initial_title ^(Save File)$, float on, size <50% <50%"
        # save image
        "match:initial_class helium, match:initial_title (.*)(wants to save)$, float on, size <50% <50%"
      ];

      custom.persist = {
        home.directories = [
          ".cache/net.imput.helium"
          ".config/net.imput.helium"
        ];
      };
    };
}
