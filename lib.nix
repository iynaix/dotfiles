{ lib, pkgs, ... }:
lib.extend (
  _: libprev: {
    # namespace for custom functions
    custom = {
      # saner api for iterating through workspaces in a flat list
      # takes a function that accepts the following attrset {workspace, key, monitor}
      mapWorkspaces =
        workspaceFn: monitors:
        libprev.concatMap (
          monitor:
          libprev.forEach monitor.workspaces (
            ws:
            let
              workspaceArg = {
                inherit monitor;
                workspace = toString ws;
                key = toString (libprev.mod ws 10);
              };
            in
            workspaceFn workspaceArg
          )
        ) monitors;

      # produces ini format strings, takes a single argument of the object
      toQuotedINI = libprev.generators.toINI {
        mkKeyValue = libprev.flip libprev.generators.mkKeyValueDefault "=" {
          mkValueString =
            v: if libprev.isString v then "\"${v}\"" else libprev.generators.mkValueStringDefault { } v;
        };
      };

      # uses the direnv of a directory
      useDirenv =
        dir: content:
        let
          direnv = libprev.getExe pkgs.direnv;
        in
        ''
          pushd ${dir} > /dev/null
          # activate direnv, it's always bash for a script
          eval "$(${direnv} export bash)"
          ${content}
          popd > /dev/null
          # deactivate direnv by evaluating in the context of the original directory
          eval "$(${direnv} export bash)"
        '';
    };
  }
)
