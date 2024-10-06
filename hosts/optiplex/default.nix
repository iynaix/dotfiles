{
  user,
  ...
}:
{
  custom = {
    # hardware
    hdds.enable = true;
    qmk.enable = false;
    zfs.encryption = false;

    # software
    bittorrent.enable = true;
    distrobox.enable = true;
    # plasma.enable = true;
    # syncoid.enable = true;
    # vercel.enable = true;
    virtualization.enable = true;
  };

  networking.hostId = "f8d69e25"; # required for zfs

  services.displayManager.autoLogin.user = user;

  networking = {
    interfaces.enp5s0.wakeOnLan.enable = true;
    # open ports for devices on the local network
    firewall.extraCommands = ''
      iptables -A nixos-fw -p tcp --source 192.168.1.0/24 -j nixos-fw-accept
    '';
  };
}
