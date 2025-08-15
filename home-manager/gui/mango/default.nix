{
  config,
  dots,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatLines
    concatStringsSep
    mkAfter
    mkBefore
    mkMerge
    mkIf
    ;
in
{
  imports = [
    ./keybinds.nix
    ./startup.nix
  ];

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
      settings = mkMerge [
        (mkBefore (
          concatLines (
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
          )
        ))
        # source it directly for quick edits
        (mkAfter "source=${dots}/home-manager/gui/mango/mango.conf")
      ];
      autostart_sh = # sh
        ''
          # startup script here
        '';

    };

    custom = {
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
