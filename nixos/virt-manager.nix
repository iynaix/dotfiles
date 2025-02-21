{
  pkgs,
  user,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.custom = {
    virtualization.enable = mkEnableOption "VM support";
  };

  config = mkIf config.custom.virtualization.enable {
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
  };
}
