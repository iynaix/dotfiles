{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf (config.custom-nixos.docker.enable || config.custom-nixos.distrobox.enable) {
  environment.systemPackages = lib.mkIf config.custom-nixos.distrobox.enable [ pkgs.distrobox ];

  virtualisation = {
    podman = {
      enable = true;
      # create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;
      # required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };

    containers.storage.settings = lib.mkIf (config.fileSystems."/".fsType == "zfs") {
      storage = {
        driver = "zfs";
        graphroot = "/var/lib/containers/storage";
        runroot = "/run/containers/storage";
      };
    };
  };

  # store docker images on zroot/cache
  custom-nixos.persist = {
    home = {
      directories = [ ".local/share/containers" ];
    };
  };
}
