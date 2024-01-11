{
  pkgs,
  user,
  config,
  lib,
  ...
}: let
  cfg = config.iynaix-nixos.vm;
in {
  config = lib.mkIf cfg.enable {
    virtualisation.libvirtd.enable = true;
    programs.virt-manager.enable = true;
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
