{
  flake.modules.nixos.programs_vlc =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.vlc ];

      custom.persist = {
        home.directories = [ ".config/vlc" ];
      };
    };
}
