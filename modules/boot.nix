{ lib, ... }:
{
  flake.nixosModules.core =
    { pkgs, ... }:
    {
      # Bootloader.
      boot = {
        initrd = {
          # enable stage-1 bootloader
          systemd.enable = true;
          # always allow booting from usb
          availableKernelModules = [ "uas" ];
        };
        loader = {
          efi = {
            canTouchEfiVariables = true;
            efiSysMountPoint = "/boot";
          };
          grub = {
            enable = true;
            devices = [ "nodev" ];
            efiSupport = true;
            theme = pkgs.custom.distro-grub-themes-nixos;
          };
          timeout = 3;
        };
        supportedFilesystems.ntfs = true;
      };

      # faster boot times
      systemd.services.NetworkManager-wait-online.wantedBy = lib.mkForce [ ];

      # reduce journald logs
      services.journald.extraConfig = "SystemMaxUse=50M";
    };
}
