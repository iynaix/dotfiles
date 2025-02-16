{
  config,
  lib,
  pkgs,
  user,
  ...
}:
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
  services.journald.extraConfig = ''SystemMaxUse=50M'';

  custom.shell.packages = {
    reboot-to-windows = {
      runtimeInputs = [ pkgs.grub2 ];
      text = # sh
        ''
          sudo grub-reboot "Windows 11"
          sudo reboot
        '';
    };
  };

  # allow rebooting directly into windows which requires sudo, see above
  security.sudo.extraRules = lib.mkIf config.hm.custom.mswindows [
    {
      users = [ user ];
      commands = [
        {
          command = lib.getExe pkgs.custom.shell.reboot-to-windows;
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
