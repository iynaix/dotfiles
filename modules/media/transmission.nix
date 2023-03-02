{ pkgs, user, lib, config, ... }:
let home = "/home/${user}"; in {
  config = lib.mkIf config.iynaix.torrenters.enable {
    # transmission dark mode, the default theme is hideous
    nixpkgs.overlays = [
      (self: super: {
        transmission = super.transmission.overrideAttrs
          (old: rec {
            themeSrc = super.fetchzip
              {
                url = "https://git.eigenlab.org/sbiego/transmission-web-soft-theme/-/archive/master/transmission-web-soft-theme-master.tar.gz";
                sha256 = "sha256-TAelzMJ8iFUhql2CX8lhysXKvYtH+cL6BCyMcpMaS9Q=";
              };
            # sed command taken from original install.sh script
            postInstall = ''
              ${old.postInstall}
              cp -RT ${themeSrc}/web/ $out/share/transmission/web/
              sed -i '21i\\t\t<link href="./style/transmission/soft-theme.min.css" type="text/css" rel="stylesheet" />\n\t\t<link href="style/transmission/soft-dark-theme.min.css" type="text/css" rel="stylesheet" />\n' $out/share/transmission/web/index.html;
            '';
          });
      })
    ];

    services = {
      transmission = {
        enable = true;
        inherit user home;
        settings = {
          alt-speed-down = 50;
          alt-speed-enabled = false;
          alt-speed-time-begin = 540;
          alt-speed-time-day = 127;
          alt-speed-time-enabled = false;
          alt-speed-time-end = 1020;
          alt-speed-up = 1000;
          bind-address-ipv4 = "0.0.0.0";
          bind-address-ipv6 = "::";
          blocklist-enabled = false;
          cache-size-mb = 4;
          compact-view = false;
          details-window-height = 525;
          details-window-width = 700;
          dht-enabled = true;
          download-dir = "${home}/Downloads/pending";
          download-queue-enabled = true;
          download-queue-size = 3;
          encryption = 1;
          idle-seeding-limit = 30;
          idle-seeding-limit-enabled = false;
          incomplete-dir = "${home}/Downloads";
          incomplete-dir-enabled = false;
          inhibit-desktop-hibernation = false;
          lpd-enabled = false;
          open-dialog-dir = home;
          peer-congestion-algorithm = "";
          peer-id-ttl-hours = 6;
          peer-limit-global = 200;
          peer-limit-per-torrent = 50;
          peer-port = 51413;
          peer-port-random-high = 65535;
          peer-port-random-low = 49152;
          peer-port-random-on-start = false;
          peer-socket-tos = "default";
          pex-enabled = true;
          port-forwarding-enabled = true;
          preallocation = 1;
          prefetch-enabled = true;
          queue-stalled-enabled = true;
          queue-stalled-minutes = 30;
          ratio-limit = 0.1000;
          ratio-limit-enabled = true;
          recent-download-dir-1 = "${home}/Downloads/pending";
          rename-partial-files = true;
          rpc-authentication-required = false;
          rpc-bind-address = "0.0.0.0";
          rpc-enabled = true;
          rpc-host-whitelist = "";
          rpc-host-whitelist-enabled = true;
          rpc-password = "{de6b0bebaa67b3a3b4f657633598cfd765d0f09a9/fP1YP.";
          rpc-port = 9091;
          rpc-url = "/transmission/";
          rpc-username = "";
          rpc-whitelist = "127.0.0.1";
          rpc-whitelist-enabled = true;
          scrape-paused-torrents-enabled = true;
          script-torrent-done-enabled = false;
          script-torrent-done-filename = null;
          seed-queue-enabled = false;
          seed-queue-size = 10;
          show-backup-trackers = false;
          show-extra-peer-details = true;
          show-filterbar = true;
          show-notification-area-icon = false;
          show-options-window = true;
          show-statusbar = true;
          show-toolbar = true;
          show-tracker-scrapes = false;
          sort-mode = "sort-by-queue";
          sort-reversed = false;
          speed-limit-down = 100;
          speed-limit-down-enabled = false;
          speed-limit-up = 100;
          speed-limit-up-enabled = true;
          start-added-torrents = true;
          statusbar-stats = "total-transfer";
          torrent-added-notification-enabled = true;
          torrent-complete-notification-enabled = true;
          torrent-complete-sound-enabled = true;
          trash-can-enabled = true;
          trash-original-torrent-files = true;
          umask = 18;
          upload-slots-per-torrent = 14;
          user-has-given-informed-consent = true;
          utp-enabled = true;
          watch-dir = "${home}/Downloads";
          watch-dir-enabled = false;
        };
      };
    };

    home-manager.users.${user} = {
      home = {
        packages = with pkgs; [ transmission-remote-gtk ];
      };
    };

    iynaix.persist.home.directories = [
      ".config/transmission-daemon/resume"
      ".config/transmission-daemon/torrents"
    ];
  };
}
