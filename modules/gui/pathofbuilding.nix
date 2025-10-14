{
  flake.modules.nixos.path-of-building =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.custom.path-of-building ];

      custom.programs.hyprland.settings = {
        # starts floating for some reason?
        windowrule = [ "tile,class:(pobfrontend)" ];
      };

      custom.persist = {
        home.directories = [ ".local/share/pobfrontend" ];
      };
    };
}
