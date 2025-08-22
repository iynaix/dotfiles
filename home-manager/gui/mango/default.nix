{
  config,
  dots,
  inputs,
  isVm,
  lib,
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
    mango.settings = lib.mkOption {
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
    home.sessionVariables = {
      # DISPLAY = ":0";
      NIXOS_OZONE_WL = "1";
    };

    wayland.windowManager.mango = {
      enable = true;
      package = inputs.mango.packages.${pkgs.system}.mango.override {
        mmsg = inputs.mango.packages.${pkgs.system}.mmsg.overrideAttrs {
          src = pkgs.fetchFromGitHub {
            owner = "DreamMaoMao";
            repo = "mmsg";
            rev = "6066d37d810bb16575c0b60e25852d1f6d50de60";
            hash = "sha256-xiQGpk987dCmeF29mClveaGJNIvljmJJ9FRHVPp92HU=";
          };
        };
      };
      systemd.enable = true;
      settings =
        (replaceString "$mod" (if isVm then "ALT" else "SUPER") (
          lib.hm.generators.toHyprconf {
            attrs = config.custom.mango.settings;
            importantPrefixes = [ "monitorrule" ];
          }
        ))
        # source it directly for quick edits
        + "source=${dots}/home-manager/gui/mango/mango.conf";
      autostart_sh = # sh
        ''
          # startup script here
        '';

    };

    custom = {
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
        ) config.custom.monitors;

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
          ) config.custom.monitors
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
