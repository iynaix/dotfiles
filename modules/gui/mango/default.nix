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
          let
            valueType =
              lib.types.nullOr (
                lib.types.oneOf [
                  lib.types.bool
                  lib.types.int
                  lib.types.float
                  lib.types.str
                  lib.types.path
                  (lib.types.attrsOf valueType)
                  (lib.types.listOf valueType)
                ]
              )
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
    { config, ... }:
    let
      inherit (config.custom.constants) dots isVm;
    in
    {
      # remove when https://github.com/NixOS/nixpkgs/pull/484963 is merged
      imports = [
        "${inputs.nixpkgs}/nixos/modules/programs/wayland/mangowc.nix"
      ];

      programs.mangowc.enable = true;

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
              ) (lib.range 1 9)
            ) config.custom.hardware.monitors
          );
        };

        print-config = {
          mango = /* sh */ ''cat "${config.hj.xdg.config.directory}/mango/config.conf" "${dots}/modules/gui/mango/mango.conf"'';
        };
      };
    };
}
