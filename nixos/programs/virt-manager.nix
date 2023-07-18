{
  pkgs,
  user,
  config,
  lib,
  ...
}: let
  cfg = config.iynaix.virt-manager;
in {
  config = lib.mkIf cfg.enable {
    virtualisation.libvirtd.enable = true;
    programs.dconf.enable = true;
    environment.systemPackages = with pkgs; [virt-manager];

    users.users.${user}.extraGroups = ["libvirtd"];
  };
}
