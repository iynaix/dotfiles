{
  pkgs,
  ...
}:
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

  environment.systemPackages = [ pkgs.brave ];

  custom.persist = {
    home.directories = [
      ".cache/BraveSoftware"
      ".config/BraveSoftware"
    ];
  };
}
