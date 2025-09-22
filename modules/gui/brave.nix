{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) getExe;
in
# mkIf (config.hm.custom.wm != "tty") {
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
      # Honey
      "bmnlcjabgnpnenekpadlanbbkooimhnj"
      # JSON Viewer
      "gbmdgpbipfallnflgajpaliibnhdgobh"
      # Looty
      # {id = "ajfbflclpnpbjkfibijekgcombcgehbi"
      # Old Reddit Redirect
      "dneaehbmnbhcippjikoajpoabadpodje"
      # PoE Wiki Search
      "nalpbalegehinpooppmmgjidgiebblad"
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
      # Surfingkeys
      "gfbliohnnapiefjpjlpjnehglfpaknnc"
      # Tokyo Night Storm
      "pgbjifpikialeahbdendkjioeafbmfkn"
      # uBlock Origin
      "cjpalhdlnbpafiamejdnhcphjbkeiagm"
      # Video Speed Controller
      "nffaoalbilbmmfgbnbgppjihopabppdk"
      # YouTube Auto HD + FPS
      "fcphghnknhkimeagdglkljinmpbagone"
      # Youtube-shorts block
      "jiaopdjbehhjgokpphdfgmapkobbnmjp"
    ];
  };

  # set default browser
  environment = {
    sessionVariables = {
      DEFAULT_BROWSER = getExe pkgs.brave;
      BROWSER = getExe pkgs.brave;
    };

    systemPackages = [ pkgs.brave ];
  };

  xdg.mime.defaultApplications = {
    "text/html" = "brave-browser.desktop";
    "x-scheme-handler/http" = "brave-browser.desktop";
    "x-scheme-handler/https" = "brave-browser.desktop";
    "x-scheme-handler/about" = "brave-browser.desktop";
    "x-scheme-handler/unknown" = "brave-browser.desktop";
  };

  hm.wayland.windowManager.hyprland.settings.windowrule = [
    # do not idle while watching videos
    "idleinhibit fullscreen,class:^(brave)$"
    "idleinhibit focus,class:^(brave)$,title:(.*)(YouTube)(.*)"
    # float save dialogs
    # save as
    "float,initialClass:^(brave)$,initialTitle:^(Save File)$"
    "size <50% <50%,initialClass:^(brave)$,initialTitle:^(Save File)$"
    # save image
    "float,initialClass:^(brave)$,initialTitle:(.*)(wants to save)$"
    "size <50% <50%,initialClass:^(brave)$,initialTitle:(.*)(wants to save)$"
  ];

  custom.persist = {
    home.directories = [
      ".cache/BraveSoftware"
      ".config/BraveSoftware"
    ];
  };
}
