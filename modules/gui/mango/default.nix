{
  inputs,
  lib,
  self,
  ...
}:
{
  flake.nixosModules.core = {
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
        description = "Mango configuration settings.";
      };
    };
  };

  flake.nixosModules.wm =
    { config, pkgs, ... }:
    let
      inherit (config.custom.constants) dots isVm;
    in
    {
      programs.mango = {
        enable = true;
        package = inputs.mango.packages.${pkgs.stdenv.hostPlatform.system}.mango;
      };

      # write the settings to home directory
      hj.xdg.config.files."mango/config.conf" = {
        text =
          (lib.replaceString "$mod" (if isVm then "ALT" else "SUPER") (
            self.libCustom.generators.toHyprconf {
              attrs = config.custom.programs.mango.settings;
              importantPrefixes = [ "monitorrule" ];
            }
          ))
          # temporarily source raw config directly for quick edits
          + "source=${dots}/modules/gui/mango/mango.conf";
        type = "copy";
      };

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
            lib.concatMapStringsSep "," toString [
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

          tagrule = lib.flatten (
            map (
              mon:
              map (
                wksp:
                lib.concatMapStringsSep "," toString [
                  "id:${toString wksp}"
                  "monitor_name:${mon.name}"
                  "layout_name:${if mon.isVertical then "vertical_tile" else "tile"}"
                ]
              ) (lib.range 1 10)
            ) config.custom.hardware.monitors
          );
        };
      };
    };
}
