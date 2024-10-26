{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf (!config.custom.headless) {
  programs.chromium = {
    enable = true;
    package = pkgs.brave;

    extensions = [
      # AutoPagerize
      { id = "igiofjhpmpihnifddepnpngfjhkfenbp"; }
      # Awesome Screen Recorder & Screenshot
      { id = "nlipoenfbbikpbjkfpfillcgkoblgpmj"; }
      # Better PathOfExile Trading
      { id = "fhlinfpmdlijegjlpgedcmglkakaghnk"; }
      # Bitwarden
      { id = "nngceckbapebfimnlniiiahkandclblb"; }
      # Dark Reader
      { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; }
      # Honey
      { id = "bmnlcjabgnpnenekpadlanbbkooimhnj"; }
      # JSON Viewer
      { id = "gbmdgpbipfallnflgajpaliibnhdgobh"; }
      # Looty
      # {id = "ajfbflclpnpbjkfibijekgcombcgehbi";}
      # Old Reddit Redirect
      { id = "dneaehbmnbhcippjikoajpoabadpodje"; }
      # PoE Wiki Search
      { id = "nalpbalegehinpooppmmgjidgiebblad"; }
      # React Dev Tools
      { id = "fmkadmapgofadopljbjfkapdkoienihi"; }
      # Reddit Enhancement Suite
      { id = "kbmfpngjjgdllneeigpgjifpgocmfgmb"; }
      # Return YouTube Dislike
      { id = "gebbhagfogifgggkldgodflihgfeippi"; }
      # Session Manager
      { id = "mghenlmbmjcpehccoangkdpagbcbkdpc"; }
      # SponsorBlock for YouTube - Skip Sponsorships
      { id = "mnjggcdmjocbbbhaepdhchncahnbgone"; }
      # Surfingkeys
      { id = "gfbliohnnapiefjpjlpjnehglfpaknnc"; }
      # uBlock Origin
      { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; }
      # Video Speed Controller
      { id = "nffaoalbilbmmfgbnbgppjihopabppdk"; }
      # YouTube Auto HD + FPS
      { id = "fcphghnknhkimeagdglkljinmpbagone"; }
      # Youtube-shorts block
      { id = "jiaopdjbehhjgokpphdfgmapkobbnmjp"; }
    ];
  };

  # set default browser
  home.sessionVariables = {
    DEFAULT_BROWSER = lib.getExe pkgs.brave;
    BROWSER = lib.getExe pkgs.brave;
  };

  xdg.mimeApps.defaultApplications = {
    "text/html" = "brave.desktop";
    "x-scheme-handler/http" = "brave.desktop";
    "x-scheme-handler/https" = "brave.desktop";
    "x-scheme-handler/about" = "brave.desktop";
    "x-scheme-handler/unknown" = "brave.desktop";
  };

  wayland.windowManager.hyprland.settings.windowrulev2 = [
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
