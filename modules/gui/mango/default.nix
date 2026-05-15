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
                url = "https://github.com/mangowm/mango/commit/b1cf48fb81fa4a8ab7121e8ac93f433b20c607c0.patch";
                hash = "sha256-r+WAK+Ww9StvXskcgp+OdmuawAGtRNCdK6521m+RYGU=";
              })
            ];
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
