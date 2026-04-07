{ lib, self, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.helium = pkgs.callPackage ./_package.nix {
        sources = self.libCustom.nvFetcherSources pkgs;
      };
    };

  flake.modules.nixos.gui =
    { pkgs, ... }:
    let
      heliumPkg = pkgs.custom.helium;
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
          # Bitwarden
          "nngceckbapebfimnlniiiahkandclblb"
          # Dark Reader
          "eimadpbcbfnmbkopoojfekhnkhdbieeh"
          # JSON Viewer
          "gbmdgpbipfallnflgajpaliibnhdgobh"
          "dneaehbmnbhcippjikoajpoabadpodje"
          # React Dev Tools
          "fmkadmapgofadopljbjfkapdkoienihi"
          # Redirector
          "lioaeidejmlpffbndjhaameocfldlhin"
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
          DEFAULT_BROWSER = lib.getExe heliumPkg;
          BROWSER = lib.getExe heliumPkg;
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

      custom.programs = {
        hyprland.settings.windowrule = [
          # do not idle while watching videos
          "match:class helium, idle_inhibit fullscreen"
          "match:class helium, match:title (.*)(YouTube)(.*), idle_inhibit focus"
          # float save dialogs
          # save as
          "match:initial_class helium, match:initial_title ^(Save File)$, float on, size <50% <50%"
          # save image
          "match:initial_class helium, match:initial_title (.*)(wants to save)$, float on, size <50% <50%"
        ];
      };

      custom.persist = {
        home.directories = [
          ".cache/net.imput.helium"
          ".config/net.imput.helium"
        ];
      };
    };
}
