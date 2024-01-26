{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.custom.deadbeef.enable {
  home.packages = [pkgs.deadbeef];

  custom.persist = {
    home.directories = [
      ".config/deadbeef"
    ];
  };
}
