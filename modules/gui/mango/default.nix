{
  config,
  dots,
  inputs,
  isVm,
  lib,
  libCustom,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatMapStringsSep
    flatten
    mkIf
    range
    replaceString
    ;
in
{
  options.custom = {
    # copied from home-manger's hypland module, since mango config is similar to hyprlang
    programs.mango.settings = lib.mkOption {
      type =
        with lib.types;
        let
          valueType =
            nullOr (oneOf [
              bool
              int
              float
              str
              path
              (attrsOf valueType)
              (listOf valueType)
            ])
            // {
              description = "Mango configuration value";
            };
        in
        valueType;
      default = { };
      description = ''Mango configuration settings.'';
    };
  };

  config = mkIf (config.custom.wm == "mango") {
    programs.mango = {
      enable = true;
      package = inputs.mango.packages.${pkgs.system}.mango;
    };

    # write the settings to home directory
    hj.xdg.config.files."mango/config.conf".text =
      (replaceString "$mod" (if isVm then "ALT" else "SUPER") (
        libCustom.toHyprconf {
          attrs = config.custom.programs.mango.settings;
          importantPrefixes = [ "monitorrule" ];
        }
      ))
      # temporarily source raw config directly for quick edits
      + "source=${dots}/modules/gui/mango/mango.conf";

    # TODO: startup scripts?

    systemd.user.targets.mango-session = {
      unitConfig = {
        Description = "mango compositor session";
        Documentation = [ "man:systemd.special(7)" ];
        BindsTo = [ "graphical-session.target" ];
        Wants = [
          "graphical-session-pre.target"
        ];
        # ++ lib.optional cfg.systemd.xdgAutostart "xdg-desktop-autostart.target";
        After = [ "graphical-session-pre.target" ];
        # Before = lib.optional cfg.systemd.xdgAutostart "xdg-desktop-autostart.target";
      };
    };

    custom.programs = {
      mango.settings = {
        monitorrule = map (
          mon:
          concatMapStringsSep "," toString [
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
        ) config.custom.hardware.monitors;

        tagrule = flatten (
          map (
            mon:
            map (
              wksp:
              concatMapStringsSep "," toString [
                "id:${toString wksp}"
                "monitor_name:${mon.name}"
                "layout_name:${if mon.isVertical then "vertical_tile" else "tile"}"
              ]
            ) (range 1 10)
          ) config.custom.hardware.monitors
        );
      };

      waybar = {
        config = {
          "dwl/tags" = {
            "num-tags" = 10;
          };
        };
        extraCss = # css
          ''
            #tags button {
              opacity: 0.6;
            }

            #tags button.occupied {
              opacity: 1;
            }
          '';
      };
    };
  };
}
