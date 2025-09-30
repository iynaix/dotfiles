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
    programs = {
      distrobox.enable = mkEnableOption "distrobox";
      docker.enable = mkEnableOption "docker" // {
        default = config.custom.programs.distrobox.enable;
      };
    };
  };

  config = mkIf (config.custom.programs.docker.enable || config.custom.programs.distrobox.enable) {
    environment.systemPackages = mkIf config.custom.programs.distrobox.enable [ pkgs.distrobox ];

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
    custom.persist = {
      home.cache = {
        directories = [ ".local/share/containers" ];
      };
    };
  };
}
