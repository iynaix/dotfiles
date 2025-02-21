{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.custom = {
    distrobox.enable = mkEnableOption "distrobox";
    docker.enable = mkEnableOption "docker" // {
      default = config.custom.distrobox.enable;
    };
  };

  config = mkIf (config.custom.docker.enable || config.custom.distrobox.enable) {
    environment.systemPackages = mkIf config.custom.distrobox.enable [ pkgs.distrobox ];

    virtualisation = {
      podman = {
        enable = true;
        # create a `docker` alias for podman, to use it as a drop-in replacement
        dockerCompat = true;
        # required for containers under podman-compose to be able to talk to each other.
        defaultNetwork.settings.dns_enabled = true;
      };

      containers.storage.settings = mkIf (config.fileSystems."/".fsType == "zfs") {
        storage = {
          driver = "zfs";
          graphroot = "/var/lib/containers/storage";
          runroot = "/run/containers/storage";
        };
      };
    };

    # store docker images on zroot/cache
    hm.custom.persist = {
      home.cache = {
        directories = [ ".local/share/containers" ];
      };
    };
  };
}
