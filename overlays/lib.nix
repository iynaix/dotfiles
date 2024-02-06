{ lib }:
{
  # saner api for iterating through workspaces in a flat list
  # takes a function that accepts the following attrset {workspace, key, monitor}
  mapWorkspaces =
    workspaceFn: displays:
    lib.concatMap
      (
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
      )
      displays;
}
