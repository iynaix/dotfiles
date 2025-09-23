{ lib, pkgs, ... }:
let
  inherit (lib)
    functionArgs
    intersectAttrs
    isDerivation
    isString
    length
    mapAttrs
    optional
    ;
in
rec {
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

  # writeShellApplication with support for completions
  writeShellApplicationCompletions =
    {
      name,
      bashCompletion ? null,
      zshCompletion ? null,
      fishCompletion ? null,
      ...
    }@shellArgs:
    let
      inherit (pkgs) writeShellApplication writeTextFile symlinkJoin;
      # get the needed arguments for writeShellApplication
      app = writeShellApplication (intersectAttrs (functionArgs writeShellApplication) shellArgs);
      completions =
        optional (bashCompletion != null) (writeTextFile {
          name = "${name}.bash";
          destination = "/share/bash-completion/completions/${name}.bash";
          text = bashCompletion;
        })
        ++ optional (zshCompletion != null) (writeTextFile {
          name = "${name}.zsh";
          destination = "/share/zsh/site-functions/_${name}";
          text = zshCompletion;
        })
        ++ optional (fishCompletion != null) (writeTextFile {
          name = "${name}.fish";
          destination = "/share/fish/vendor_completions.d/${name}.fish";
          text = fishCompletion;
        });
    in
    if length completions == 0 then
      app
    else
      symlinkJoin {
        inherit name;
        inherit (app) meta;
        paths = [ app ] ++ completions;
      };

  # produces an attrset shell package with completions from either a string / writeShellApplication attrset / package
  mkShellPackages = mapAttrs (
    name: value:
    if isString value then
      pkgs.writeShellApplication {
        inherit name;
        text = value;
      }
    # packages
    else if isDerivation value then
      value
    # attrs to pass to writeShellApplication
    else
      writeShellApplicationCompletions (value // { inherit name; })
  );

  # produces ini format strings, takes a single argument of the object
  toQuotedINI = lib.generators.toINI {
    mkKeyValue = lib.flip lib.generators.mkKeyValueDefault "=" {
      mkValueString = v: if lib.isString v then "\"${v}\"" else lib.generators.mkValueStringDefault { } v;
    };
  };

  # uses the direnv of a directory
  direnvCargoRun =
    {
      dir,
      bin ? builtins.baseNameOf dir,
      args ? "",
    }:
    # sh
    ''
      pushd ${dir} > /dev/null
      ${lib.getExe pkgs.direnv} exec "${dir}" cargo run --release --bin "${bin}" --manifest-path "${dir}/Cargo.toml" -- ${args} "$@"
      popd > /dev/null
    '';

  # checks if a file exists and returns the path to it, otherwise returns the fallback, in a format
  # suitable for passing into sed
  fallbackPath =
    runtime: fallback:
    # NOTE: | is the character used for sed separator, & is a metacharacter for matched string
    ''\$( [ -e \"${runtime}\" ] \&\& echo \"${runtime}\" \|\| echo \"${fallback}\" )'';

  # create a shell wrapper that checks for a config file at runtime and uses that if it exists
  # falling back to the default config in the nix store otherwise
  wrapperWithRuntimeConfig =
    substitutions: wrapperArgs:
    wrapperArgs
    // {
      wrapperType = "shell";
      postBuild =
        (wrapperArgs.postBuild or "")
        + (
          substitutions
          |> lib.mapAttrsToList (name: value: ''"s|'*${name}'*|${value}|g"'')
          |> lib.concatStringsSep "; "
          |> (s: "sed -i ${s} $out/bin/${wrapperArgs.basePackage.meta.mainProgram}")
        );
    };
}
