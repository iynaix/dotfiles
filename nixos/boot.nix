{
  config,
  lib,
  pkgs,
  user,
  ...
}:
let
  inherit (lib) getExe mkForce mkIf;
in
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
  systemd.services.NetworkManager-wait-online.wantedBy = mkForce [ ];

  # reduce journald logs
  services.journald.extraConfig = ''SystemMaxUse=50M'';

  custom.shell.packages = {
    reboot-to-windows = {
      runtimeInputs = [ pkgs.grub2 ];
      text = # sh
        ''
          grub-reboot "Windows 11"
          reboot
        '';
    };
  };

  # allow rebooting directly into windows which requires sudo, see above
  security.sudo.extraRules = mkIf config.hm.custom.mswindows [
    {
      users = [ user ];
      commands = [
        {
          command = getExe pkgs.custom.shell.reboot-to-windows;
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
