{ lib, ... }:
{
  flake.nixosModules.battery = {
    custom.programs.waybar.config = {
      battery = {
        format = "{icon}    {capacity}%";
        format-charging = "     {capacity}%";
        format-icons = [
          ""
          ""
          ""
          ""
          ""
        ];
        states = {
          critical = 20;
        };
        tooltip = false;
      };

      modules-right = lib.mkOrder 700 [ "battery" ];
    };
  };
}
