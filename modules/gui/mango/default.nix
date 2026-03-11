{
  lib,
  self,
  ...
}:
{
  flake.modules.nixos.core = {
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

  flake.modules.nixos.wm =
    { config, pkgs, ... }:
    let
      inherit (config.custom.constants) dots isVm;
    in
    {
      programs.mangowc = {
        enable = true;
        package = pkgs.mangowc.overrideAttrs (
          o:
          (self.libCustom.nvFetcherSources pkgs).mango
          // {
            patches = (o.patches or [ ]) ++ [
              # adds niri inspired atstartup rule:
              # https://github.com/DreamMaoMao/mangowc/pull/654
              (pkgs.fetchurl {
                url = "https://github.com/mangowm/mango/commit/b1cf48fb81fa4a8ab7121e8ac93f433b20c607c0.patch";
                hash = "sha256-mEC2Vkn4IuSGXCPPRQ0lzY5sBxk+BFDbygKD2XY7pgs=";
              })
            ];
          }
        );
      };

      # write the settings to home directory
      hj.xdg.config.files."mango/config.conf" =
        let
          contents = lib.replaceString "$mod" (if isVm then "ALT" else "SUPER") (
            self.libCustom.generators.toHyprconf {
              attrs = config.custom.programs.mango.settings;
              importantPrefixes = [ "monitorrule" ];
            }
          );
          # validate if config is valid
          checkedMangoConf = pkgs.runCommand "check-mango-conf" { } ''
            # write $out with source directives
            cat > "$out" <<'EOF'
            ${contents}
            source-optional=${dots}/modules/gui/mango/mango.conf
            source-optional=~/.config/mango/noctalia.conf
            EOF

            # filter out the source directives for validation, the nix sandbox won't have those files
            # concat the mango.conf for validation
            cat $out ${./mango.conf} >> config_full.conf

            ${lib.getExe config.programs.mangowc.package} -c config_full.conf -p
          '';
        in
        {
          source = checkedMangoConf;
          type = "copy";
        };

      custom.programs = {
        mango.settings = {
          monitorrule = map (
            mon:
            lib.concatMapStringsSep "," toString [
              "name:${mon.name}"
              "rr:${toString mon.transform}"
              "scale:${toString mon.scale}"
              "x:${toString mon.x}"
              "y:${toString mon.y}"
              "width:${toString mon.width}"
              "height:${toString mon.height}"
              "refresh:${toString mon.refreshRate}"
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
                  "mfact:0.5"
                  "nmaster:1"
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
