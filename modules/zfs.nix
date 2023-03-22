{
  config,
  pkgs,
  user,
  lib,
  inputs,
  ...
}: {
  options.iynaix.zfs = {
    enable = lib.mkEnableOption "Enable zfs" // {default = true;};
  };

  config = {
    # booting with zfs
    boot.supportedFilesystems = ["zfs"];
    boot.zfs.devNodes = lib.mkDefault "/dev/disk/by-id";

    services.zfs = {
      autoScrub.enable = true;
      trim.enable = true;
    };

    # standard zfs filesystem layout
    fileSystems."/" = {
      device = "zroot/local/root";
      fsType = "zfs";
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-label/NIXBOOT";
      fsType = "vfat";
    };

    fileSystems."/nix" = {
      device = "zroot/local/nix";
      fsType = "zfs";
    };

    fileSystems."/home" = {
      device = "zroot/safe/home";
      fsType = "zfs";
    };

    fileSystems."/persist" = {
      device = "zroot/safe/persist";
      fsType = "zfs";
    };
  };
}
