{ lib, pkgs }:
{
  # saner api for iterating through workspaces in a flat list
  # takes a function that accepts the following attrset {workspace, key, monitor}
  mapWorkspaces =
    workspaceFn: displays:
    lib.concatMap (
      { name, workspaces, ... }:
      lib.forEach workspaces (
        ws:
        let
          workspaceArg = {
            workspace = toString ws;
            key = toString (lib.mod ws 10);
            monitor = name;
          };
        in
        workspaceFn workspaceArg
      )
    ) displays;

  # produces ini format strings, takes a single argument of the object
  toQuotedINI = lib.generators.toINI {
    mkKeyValue = lib.flip lib.generators.mkKeyValueDefault "=" {
      mkValueString = v: if lib.isString v then "\"${v}\"" else lib.generators.mkValueStringDefault { } v;
    };
  };

  createShellScriptBins = lib.mapAttrsToList (name: content: pkgs.writeShellScriptBin name content);
}
