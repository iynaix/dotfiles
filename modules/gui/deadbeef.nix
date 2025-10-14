{
  flake.modules.nixos.deadbeef =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.deadbeef ];

      custom.persist = {
        home.directories = [ ".config/deadbeef" ];
      };
    };
}
