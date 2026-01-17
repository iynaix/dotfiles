{ lib, ... }:
{
  flake.libCustom = rec {
    generators = {
      # produces ini format strings, takes a single argument of the object
      toQuotedINI = lib.generators.toINI {
        mkKeyValue = lib.flip lib.generators.mkKeyValueDefault "=" {
          mkValueString = v: if lib.isString v then "\"${v}\"" else lib.generators.mkValueStringDefault { } v;
        };
      };
    };

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
  };
}
