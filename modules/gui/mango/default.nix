{
  inputs,
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
      mangowc' = inputs.wrappers.wrappers.mangowc.wrap {
        inherit pkgs;
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
        configFile.content = lib.replaceString "$mod" (if isVm then "ALT" else "SUPER") (
          self.libCustom.generators.toHyprconf {
            attrs = config.custom.programs.mango.settings;
            importantPrefixes = [ "monitorrule" ];
          }
        );
      };
    in
    {
      programs.mangowc = {
        enable = true;
        package = mangowc'.wrap {
          configFile.content = ''
            source-optional=${dots}/modules/gui/mango/mango.conf
            source-optional=${config.hj.xdg.config.directory}/mango/noctalia.conf
          '';
        };
      };

      custom.programs = {
        print-config = {
          mango = /* sh */ ''cat "${config.programs.mangowc.package.configuration.constructFiles.generatedConfig.outPath}" "${dots}/modules/gui/mango/mango.conf" "${config.hj.xdg.config.directory}/mango/noctalia.conf" | moor'';
        };
      };
    };
}
