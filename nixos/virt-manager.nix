{
  pkgs,
  user,
  config,
  lib,
  ...
}: let
  cfg = config.custom-nixos.vm;
in {
  config = lib.mkIf cfg.enable {
    virtualisation.libvirtd.enable = true;
    programs.virt-manager.enable = true;
    # https://discourse.nixos.org/t/virt-manager-cannot-find-virtiofsd/26752/2
    # add virtiofsd to filesystem xml
    # <binary path="/run/current-system/sw/bin/virtiofsd"/>
    environment.systemPackages = with pkgs; [
      virtiofsd
    ];

    users.users.${user}.extraGroups = ["libvirtd"];

    # store VMs on zroot/cache
    environment.persistence."/persist/cache/VMs" = {
      hideMounts = true;

      directories = [
        "/var/lib/libvirt"
      ];
    };
  };
}
