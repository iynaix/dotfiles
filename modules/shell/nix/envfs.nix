{ lib, ... }:
{
  flake.nixosModules.core =
    { config, ... }:
    {
      # execute shebangs that assume hardcoded shell paths
      services.envfs.enable = true;

      # workaround systemd "Refusing to run in unsupported environment where /usr/ is not populated."
      # error with tmpfs:
      # https://github.com/Mic92/envfs/issues/203
      boot.initrd.systemd.tmpfiles.settings = lib.mkIf config.boot.initrd.systemd.enable {
        "50-usr-bin" = {
          "/sysroot/usr/bin" = {
            d = {
              group = "root";
              mode = "0755";
              user = "root";
            };
          };
        };
      };

      fileSystems = lib.mkIf config.boot.initrd.systemd.enable {
        "/usr/bin".options = [
          "x-systemd.requires=modprobe@fuse.service"
          "x-systemd.after=modprobe@fuse.service"
        ];

        "/bin".enable = false;
      };
    };
}
