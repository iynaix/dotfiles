{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) getExe;
in
{
  custom = {
    specialisation = {
      hyprland.enable = true;
    };

    # don't blind me on startup
    startup = [
      {
        spawn = [
          (getExe pkgs.brightnessctl)
          "s"
          "20%"
        ];
      }
    ];

    persist = {
      home.directories = [ "Downloads" ];
    };
  };

}
