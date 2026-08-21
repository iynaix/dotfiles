{
  tags = [ "gui" ];

  config =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.libreoffice ];

      custom.persist = {
        home.directories = [ ".config/libreoffice" ];
      };
    };
}
