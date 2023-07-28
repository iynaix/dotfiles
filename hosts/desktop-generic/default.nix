{...}: {
  iynaix-nixos = {
    # hardware
    am5.enable = false;
    hdds.enable = false;
    nvidia.enable = true;

    # software
    distrobox.enable = true;
    hyprland-nixos.enable = true;
    torrenters.enable = false;
    virt-manager.enable = true;
  };

  networking.hostId = "89eaa833"; # required for zfs

  # open ports for devices on the local network
  networking.firewall.extraCommands = ''
    iptables -A nixos-fw -p tcp --source 192.168.1.0/24 -j nixos-fw-accept
  '';
}
