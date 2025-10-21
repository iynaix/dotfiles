{ lib, ... }:
{
  flake.lib = rec {
    # saner api for iterating through workspaces in a flat list
    # takes a function that accepts the following attrset {workspace, key, monitor}
    mapWorkspaces =
      workspaceFn:
      lib.concatMap (
        monitor:
        map (
          ws:
          let
            workspaceArg = {
              inherit monitor;
              workspace = toString ws;
              key = toString (lib.mod ws 10);
            };
          in
          workspaceFn workspaceArg
        ) monitor.workspaces
      );

    # https://discourse.nixos.org/t/nix-function-to-merge-attributes-records-recursively-and-concatenate-arrays/2030/9
    recursiveMergeAttrs =
      lhs: rhs:
      lhs
      // rhs
      // (lib.mapAttrs (
        name: value:
        if (lib.hasAttr name lhs && lib.isAttrs value && lib.isAttrs lhs.${name}) then
          recursiveMergeAttrs lhs.${name} value
        else if (lib.hasAttr name lhs && lib.isList value && lib.isList lhs.${name}) then
          lhs.${name} ++ value
        else
          value
      ) rhs);

    recursiveMergeAttrsList = attrsets: lib.foldl' recursiveMergeAttrs { } attrsets;

    generators = {
      # produces ini format strings, takes a single argument of the object
      toQuotedINI = lib.generators.toINI {
        mkKeyValue = lib.flip lib.generators.mkKeyValueDefault "=" {
          mkValueString = v: if lib.isString v then "\"${v}\"" else lib.generators.mkValueStringDefault { } v;
        };
      };

      # copied from home-manager:
      # https://github.com/nix-community/home-manager/blob/master/modules/lib/generators.nix
      toHyprconf =
        {
          attrs,
          indentLevel ? 0,
          importantPrefixes ? [ "$" ],
        }:
        let
          inherit (lib)
            all
            concatMapStringsSep
            concatStrings
            concatStringsSep
            filterAttrs
            foldl
            generators
            hasPrefix
            isAttrs
            isList
            mapAttrsToList
            replicate
            ;

          initialIndent = concatStrings (replicate indentLevel "  ");

          toHyprconf' =
            indent: attrs:
            let
              sections = filterAttrs (_n: v: isAttrs v || (isList v && all isAttrs v)) attrs;

              mkSection =
                n: attrs:
                if lib.isList attrs then
                  (concatMapStringsSep "\n" (a: mkSection n a) attrs)
                else
                  ''
                    ${indent}${n} {
                    ${toHyprconf' "  ${indent}" attrs}${indent}}
                  '';

              mkFields = generators.toKeyValue {
                listsAsDuplicateKeys = true;
                inherit indent;
              };

              allFields = filterAttrs (_n: v: !(isAttrs v || (isList v && all isAttrs v))) attrs;

              isImportantField =
                n: _: foldl (acc: prev: if hasPrefix prev n then true else acc) false importantPrefixes;

              importantFields = filterAttrs isImportantField allFields;

              fields = builtins.removeAttrs allFields (mapAttrsToList (n: _: n) importantFields);
            in
            mkFields importantFields
            + concatStringsSep "\n" (mapAttrsToList mkSection sections)
            + mkFields fields;
        in
        toHyprconf' initialIndent attrs;
    };

    # hyprland settings type, copied from home-manager:
    # https://github.com/nix-community/home-manager/blob/master/modules/services/window-managers/hyprland.nix
    types = {
      hyprlandSettingsType = lib.mkOption {
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
                description = "Hyprland configuration value";
              };
          in
          valueType;
        default = { };
        description = ''
          Hyprland configuration written in Nix. Entries with the same key
          should be written as lists. Variables' and colors' names should be
          quoted. See <https://wiki.hypr.land> for more examples.
        '';
        example = lib.literalExpression ''
          {
            decoration = {
              shadow_offset = "0 5";
              "col.shadow" = "rgba(00000099)";
            };

            "$mod" = "SUPER";

            bindm = [
              # mouse movements
              "$mod, mouse:272, movewindow"
              "$mod, mouse:273, resizewindow"
              "$mod ALT, mouse:272, resizewindow"
            ];
          }
        '';
      };
    };
  };
}
