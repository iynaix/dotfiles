{
  inputs,
  lib,
  self,
  ...
}:
let
  # copied from home-manager:
  # https://github.com/nix-community/home-manager/blob/master/modules/lib/generators.nix
  toMangoConf =
    {
      attrs,
      indentLevel ? 0,
      importantPrefixes ? [ "$" ],
    }:
    let
      initialIndent = lib.concatStrings (lib.replicate indentLevel "  ");

      toMangoConf' =
        indent: attrs:
        let
          sections = lib.filterAttrs (_n: v: lib.isAttrs v || (lib.isList v && lib.all lib.isAttrs v)) attrs;

          mkSection =
            n: attrs:
            if lib.isList attrs then
              (lib.concatMapStringsSep "\n" (a: mkSection n a) attrs)
            else
              ''
                ${indent}${n} {
                ${toMangoConf' "  ${indent}" attrs}${indent}}
              '';

          mkFields = lib.generators.toKeyValue {
            listsAsDuplicateKeys = true;
            inherit indent;
          };

          allFields = lib.filterAttrs (
            _n: v: !(lib.isAttrs v || (lib.isList v && lib.all lib.isAttrs v))
          ) attrs;

          isImportantField =
            n: _: lib.foldl (acc: prev: if lib.hasPrefix prev n then true else acc) false importantPrefixes;

          importantFields = lib.filterAttrs isImportantField allFields;

          fields = removeAttrs allFields (lib.mapAttrsToList (n: _: n) importantFields);
        in
        mkFields importantFields
        + lib.concatStringsSep "\n" (lib.mapAttrsToList mkSection sections)
        + mkFields fields;
    in
    toMangoConf' initialIndent attrs;
in
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
      inherit (config.custom.constants) isVm;
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
                url = "https://github.com/mangowm/mango/commit/46a5d4445b1e5f4e27a340f47ec31a55ca922ba9.patch";
                hash = "sha256-HT8jdfvlQKV35lyzaISfBUAIDy0PUGNOhdiTo9LB0+0=";
              })
            ];

            buildInputs =
              assert lib.assertMsg (lib.versionOlder pkgs.mangowc.version "0.14.0")
                "remove mangowc cjson buildInputs override";
              (o.buildInputs or [ ]) ++ [ pkgs.cjson ];
          }
        );
        configFile.content = lib.replaceString "$mod" (if isVm then "ALT" else "SUPER") (toMangoConf {
          attrs = config.custom.programs.mango.settings;
          importantPrefixes = [ "monitorrule" ];
        });
      };
    in
    {
      programs.mangowc = {
        enable = true;
        package = mangowc'.wrap {
          configFile.content = ''
            source-optional=${config.hj.xdg.config.directory}/mango/noctalia.conf
          '';
        };
      };

      custom.programs = {
        print-config = {
          mango = /* sh */ ''cat "${config.programs.mangowc.package.configuration.constructFiles.generatedConfig.outPath}" "${config.hj.xdg.config.directory}/mango/noctalia.conf" | moor'';
        };
      };
    };
}
