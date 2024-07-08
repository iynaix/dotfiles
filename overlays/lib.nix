{ lib, pkgs, ... }:
{
  # saner api for iterating through workspaces in a flat list
  # takes a function that accepts the following attrset {workspace, key, monitor}
  mapWorkspaces =
    workspaceFn: monitors:
    lib.concatMap (
      monitor:
      lib.forEach monitor.workspaces (
        ws:
        let
          workspaceArg = {
            inherit monitor;
            workspace = toString ws;
            key = toString (lib.mod ws 10);
          };
        in
        workspaceFn workspaceArg
      )
    ) monitors;

  # produces ini format strings, takes a single argument of the object
  toQuotedINI = lib.generators.toINI {
    mkKeyValue = lib.flip lib.generators.mkKeyValueDefault "=" {
      mkValueString = v: if lib.isString v then "\"${v}\"" else lib.generators.mkValueStringDefault { } v;
    };
  };

  # uses the direnv of a directory
  useDirenv =
    dir: text:
    let
      direnv = lib.getExe pkgs.direnv;
    in
    ''
      pushd ${dir} > /dev/null
      # activate direnv, it's always bash for a script
      ${direnv} allow && eval "$(${direnv} export bash)"
      ${text}
      popd > /dev/null
      # deactivate direnv by evaluating in the context of the original directory
      eval "$(${direnv} export bash)"
    '';
}
