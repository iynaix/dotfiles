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
    # enable stage-1 bootloader
    initrd.systemd.enable = true;
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
    };
    supportedFilesystems.ntfs = true;
  };

  custom.shell.packages = {
    reboot-to-windows = {
      runtimeInputs = [ pkgs.grub2 ];
      text = ''
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
