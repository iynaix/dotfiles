{ lib, pkgs, ... }:
let
  inherit (lib) getExe;
  heliumPkg = pkgs.custom.helium;
in
{
  programs.chromium = {
    enable = true;

    extensions = [
      # AutoPagerize
      "igiofjhpmpihnifddepnpngfjhkfenbp"
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
      # {id = "ajfbflclpnpbjkfibijekgcombcgehbi"
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
    "idleinhibit fullscreen,class:^(helium)$"
    "idleinhibit focus,class:^(helium)$,title:(.*)(YouTube)(.*)"
    # float save dialogs
    # save as
    "float,initialClass:^(helium)$,initialTitle:^(Save File)$"
    "size <50% <50%,initialClass:^(helium)$,initialTitle:^(Save File)$"
    # save image
    "float,initialClass:^(helium)$,initialTitle:(.*)(wants to save)$"
    "size <50% <50%,initialClass:^(helium)$,initialTitle:(.*)(wants to save)$"
  ];

  custom.persist = {
    home.directories = [
      ".cache/net.imput.helium"
      ".config/net.imput.helium"
    ];
  };
}
