{user, ...}: {
  iynaix-nixos = {
    # hardware
    am5.enable = true;
    hdds = {
      enable = true;
      archlinux = false;
    };
    nvidia.enable = true;

    # software
    distrobox.enable = true;
    syncoid.enable = true;
    bittorrent.enable = true;
    vercel.enable = true;
    virt-manager.enable = true;
  };

  services.xserver.displayManager.autoLogin.user = user;

  networking.hostId = "89eaa833"; # required for zfs

  # open ports for devices on the local network
  networking.firewall.extraCommands = ''
    iptables -A nixos-fw -p tcp --source 192.168.1.0/24 -j nixos-fw-accept
  '';
}
