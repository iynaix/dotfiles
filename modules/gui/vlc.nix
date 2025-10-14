{
  flake.modules.nixos.vlc =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.vlc ];

      custom.persist = {
        home.directories = [ ".config/vlc" ];
      };
    };
}
