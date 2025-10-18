{
  flake.modules.nixos.docker =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.distrobox ];

      virtualisation = {
        podman = {
          enable = true;
          # create a `docker` alias for podman, to use it as a drop-in replacement
          dockerCompat = true;
          # required for containers under podman-compose to be able to talk to each other.
          defaultNetwork.settings.dns_enabled = true;
        };

        containers.storage.settings = {
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
