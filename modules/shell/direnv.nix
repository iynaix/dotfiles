{
  user,
  lib,
  host,
  ...
}: {
  config = {
    home-manager.users.${user} = {
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
    };

    # open ports for devices on the local network
    networking.firewall.extraCommands = lib.mkIf (host == "desktop") ''
      iptables -A nixos-fw -p tcp --source 192.168.1.0/24 -j nixos-fw-accept
    '';
  };
}
