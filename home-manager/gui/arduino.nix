# NOTE: This is temporary I plan on migrating to helix for arduino (not that I'll ever use it).
{
  pkgs,
  lib,
  ...
}:
{
  config = lib.mkMerge [
    {
      custom.persist = {
        home.directories = [
          "arduino"
        ];
      };
      home = {
        packages = with pkgs; [
          arduino-ide
        ];
      };
    }
  ];
}
