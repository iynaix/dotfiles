{
  flake.nixosModules.deadbeef =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.deadbeef ];

      custom.persist = {
        home.directories = [ ".config/deadbeef" ];
      };
    };
}
