{
  config,
  lib,
  pkgs,
  user,
  ...
}:
let
  homeDir = "/persist${config.hm.home.homeDirectory}";
  proj_dir = "/persist${config.hm.home.homeDirectory}/projects";
  downloadDir = "/media/IRONWOLF22/Downloads";
  pendingDir = "${downloadDir}/pending";
in
lib.mkIf config.custom-nixos.bittorrent.enable (
  lib.mkMerge [
    {
      services.transmission = {
        enable = true;
        package = pkgs.transmission_4;
        webHome = pkgs.flood-for-transmission;
        inherit user;
        home = homeDir;
        group = "users";
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
          download-dir = pendingDir;
          download-queue-enabled = true;
          download-queue-size = 3;
          encryption = 1;
          idle-seeding-limit = 30;
          idle-seeding-limit-enabled = false;
          incomplete-dir = downloadDir;
          incomplete-dir-enabled = false;
          inhibit-desktop-hibernation = false;
          lpd-enabled = false;
          message-level = 1;
          open-dialog-dir = homeDir;
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
          ratio-limit = 0.1;
          ratio-limit-enabled = true;
          recent-download-dir-1 = pendingDir;
          rename-partial-files = true;
          rpc-authentication-required = false;
          rpc-bind-address = "0.0.0.0";
          rpc-enabled = true;
          rpc-host-whitelist = "";
          rpc-host-whitelist-enabled = true;
          rpc-port = 9091;
          rpc-url = "/transmission/";
          rpc-username = "";
          rpc-whitelist = "127.0.0.1,192.168.1.*";
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
          watch-dir = downloadDir;
          watch-dir-enabled = false;
        };
      };

      # setup port forwarding
      networking.firewall.allowedTCPPorts = [ 51413 ];

      # xdg handler for magnet links
      hm = {
        xdg = {
          desktopEntries.transmission = {
            name = "Transmission";
            genericName = "BitTorrent Client";
            icon = "transmission";
            exec = "transmission-remote -a %U";
          };

          mimeApps.defaultApplications = {
            "x-scheme-handler/magnet" = "transmission.desktop";
          };
        };
      };

      custom-nixos = {
        persist.home.directories = [ ".config/transmission-daemon" ];

        # process downloaded files
        shell.packages = {
          renamer = pkgs.custom.lib.useDirenv "${proj_dir}/renamer" ''cargo run --release --bin renamer'';
        };
      };
    }

    # only setup rpc password if sops is enabled
    (lib.mkIf config.custom-nixos.sops.enable {
      sops.secrets.transmission_rpc.owner = user;

      services.transmission.credentialsFile = config.sops.secrets.transmission_rpc.path;
    })
  ]
)
