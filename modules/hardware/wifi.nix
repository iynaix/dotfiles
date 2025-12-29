{
  flake.nixosModules.wifi = {
    custom.persist = {
      root.directories = [ "/etc/NetworkManager" ];
    };
  };
}
