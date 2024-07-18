{
  config,
  lib,
  pkgs,
  user,
  ...
}:
{
  custom = {
    # hardware
    hdds.enable = true;
    nvidia.enable = true;
    qmk.enable = false;
    zfs.encryption = false;

    # software
    bittorrent.enable = true;
    distrobox.enable = true;
    # plasma.enable = true;
    syncoid.enable = true;
    vercel.enable = true;
    vm.enable = true;
  };

  networking.hostId = "89eaa833"; # required for zfs

  services.displayManager.autoLogin.user = user;

  # open ports for devices on the local network
  networking.firewall.extraCommands = ''
    iptables -A nixos-fw -p tcp --source 192.168.1.0/24 -j nixos-fw-accept
  '';

  # enable flirc usb ir receiver
  hardware.flirc.enable = false;
  environment.systemPackages = lib.mkIf config.hardware.flirc.enable [ pkgs.flirc ];

  # fix intel i225-v ethernet dying due to power management
  # https://reddit.com/r/buildapc/comments/xypn1m/network_card_intel_ethernet_controller_i225v_igc/
  # boot.kernelParams = ["pcie_port_pm=off" "pcie_aspm.policy=performance"];
}
