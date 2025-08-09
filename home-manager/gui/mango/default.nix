{
  config,
  lib,
  user,
  ...
}:
let
  inherit (lib)
    concatLines
    concatStringsSep
    mkIf
    mkOption
    ;
  inherit (lib.types) lines;
in
{
  imports = [
    ./keybinds.nix
    ./startup.nix
  ];

  options.custom = {
    mango = {
      settings = mkOption {
        type = lines;
        default = "";
        description = "Settings for mangowc";
      };
    };
  };

  config = mkIf (config.custom.wm == "mango") {
    wayland.windowManager.mango = {
      enable = true;
      systemd.enable = true;
      # TODO: replace with actual config when almost done
      settings = config.custom.mango.settings + ''
        source=/persist/home/${user}/.config/mango/config.conf
      '';
      # autostart_sh = ''

      # '';

    };

    custom.mango.settings = concatLines (
      map (
        mon:
        "monitorrule="
        + (concatStringsSep "," (
          map toString [
            mon.name
            0.5 # mfact
            1 # nmaster
            "tile" # layout
            mon.transform
            mon.scale
            mon.positionX
            mon.positionY
            mon.width
            mon.height
            mon.refreshRate
          ]
        ))
      ) config.custom.monitors
    );
  };
}
