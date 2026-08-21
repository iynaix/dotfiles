{
  hosts = [ "desktop" ];

  config =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.vlc ];

      custom.persist = {
        home.directories = [ ".config/vlc" ];
      };
    };
}
