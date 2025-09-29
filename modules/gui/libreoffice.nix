{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
in
mkIf (config.custom.wm != "tty") {
  environment.systemPackages = [ pkgs.libreoffice ];

  custom.persist = {
    home.directories = [ ".config/libreoffice" ];
  };
}
