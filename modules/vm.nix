{
  flake.nixosModules.virtualisation =
    { config, pkgs, ... }:
    let
      inherit (config.custom.constants) user;
    in
    {
      config = {
        virtualisation = {
          libvirtd.enable = true;
          # following configuration is used only when building VMs with build-vm
          vmVariant = {
            virtualisation = {
              memorySize = 1024 * 16;
              cores = 8;
            };
          };
        };
        programs.virt-manager.enable = true;
        # https://discourse.nixos.org/t/virt-manager-cannot-find-virtiofsd/26752/2
        # add virtiofsd to filesystem xml
        # <binary path="/run/current-system/sw/bin/virtiofsd"/>
        environment.systemPackages = with pkgs; [ virtiofsd ];

        users.users.${user}.extraGroups = [ "libvirtd" ];

        # store VMs on zroot/cache
        custom.persist = {
          root = {
            cache.directories = [ "/var/lib/libvirt" ];
          };
        };
      };
    };
}
