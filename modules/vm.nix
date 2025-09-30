{
  pkgs,
  user,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkMerge;
in
{
  options.custom = {
    services.virtualization.enable = mkEnableOption "VM support";
  };

  config = mkMerge [
    (mkIf config.custom.services.virtualization.enable {
      virtualisation.libvirtd.enable = true;
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
    })

    {
      virtualisation.vmVariant = {
        # following configuration is added only when building VM with build-vm
        virtualisation = {
          memorySize = 1024 * 16;
          cores = 8;
        };
      };
    }
  ];
}
