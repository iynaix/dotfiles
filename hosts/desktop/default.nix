{ user, ... }:
{
  custom = {
    # hardware
    hdds.enable = true;
    nvidia.enable = true;
    qmk.enable = false;
    zfs.encryption = false;

    # software
    distrobox.enable = true;
    syncoid.enable = true;
    bittorrent.enable = true;
    vercel.enable = true;
    vm.enable = true;
  };

  networking.hostId = "89eaa833"; # required for zfs

  # by-id doesn't seem to work with b650e mobo
  boot.zfs.devNodes = "/dev/disk/by-partuuid";

  services.displayManager.autoLogin.user = user;

  # open ports for devices on the local network
  networking.firewall.extraCommands = ''
    iptables -A nixos-fw -p tcp --source 192.168.1.0/24 -j nixos-fw-accept
  '';

  # fix intel i225-v ethernet dying due to power management
  # https://reddit.com/r/buildapc/comments/xypn1m/network_card_intel_ethernet_controller_i225v_igc/
  # boot.kernelParams = ["pcie_port_pm=off" "pcie_aspm.policy=performance"];

  # fix clock to be compatible with windows
  time.hardwareClockInLocalTime = true;
}
