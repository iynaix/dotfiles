{
  flake.nixosModules.host-desktop =
    { config, lib, ... }:
    let
      hgst10 = "/media/HGST10";
      ironwolf22 = "/media/IRONWOLF22";
    in
    {
      services.sanoid = {
        datasets = {
          "zfs-hgst10-1/media" = {
            hourly = 3;
            daily = 10;
            weekly = 2;
            monthly = 0;
          };
          "zfs-ironwolf22-1/media" = {
            hourly = 3;
            daily = 10;
            weekly = 2;
            monthly = 0;
          };
        };
      };

      custom = {
        # symlinks from hdds
        symlinks = {
          "${config.hj.directory}/Downloads" = "${ironwolf22}/Downloads";
          "${config.hj.directory}/Videos" = hgst10;
        };

        # add btop monitoring for extra hdds
        programs.btop.disks = [
          hgst10
          ironwolf22
        ];

        gtk.bookmarks = lib.mkAfter [
          "${hgst10}/Anime Anime"
          "${hgst10}/Anime/Current Anime Current"
          "${hgst10}/TV TV"
          "${hgst10}/TV/Current TV Current"
          "${hgst10}/Movies"
        ];
      };

      fileSystems = {
        "/media/HGST10" = {
          device = "zfs-hgst10-1/media";
          fsType = "zfs";
        };

        "/media/IRONWOLF22" = {
          device = "zfs-ironwolf22-1/media";
          fsType = "zfs";
        };

      };
    };
}
