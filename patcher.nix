# Adapted from flake-input-patcher:
# https://github.com/jfly/flake-input-patcher/blob/3e30fd3bbf9ead4863d06c61407654a9be815fc9/lib-deprecated.nix
#
# flake-input-patcher reads flake.lock, which tack does not use.
#
# Trying to use the deprecated patchV1 that does not read the lockfile
# results in a giant annoying warning.
#
# Using the follows-without-lockfile-abandoned branch causes infinite recursion.
{
  lib,
  fetchpatch,
  fetchpatch2,
  fetchurl,
  stdenvNoCC,
  ...
}:
let
  # This logic is largely copied from nix itself, see
  # <https://github.com/NixOS/nix/blob/2.29.0/src/libflake/call-flake.nix>.
  # We can't use `builtins.getFlake` for two reasons:
  #  1. Nix treats this as an "unlocked" flake reference and errors out in pure
  #     mode. I suspect this is a bug, perhaps one that only arises when doing
  #     IFD like we're doing here.
  #  2. We need to load the flake with the given (possibly patched) inputs.
  importFlake =
    {
      src,
      inputs,
      sourceInfo ? { },
    }:
    let
      flake = import (src + "/flake.nix");
      outPath = toString src;
      # I'm not sure what to do with `sourceInfo`. It normally comes from the
      # lockfile [0]. Copying the old value feels wrong.
      # I'm going to opt to leave it unset until something goes wrong.
      #
      # [0]: https://github.com/NixOS/nix/blob/2.29.0/src/libflake/call-flake.nix#L52-L63
      finalSourceInfo = sourceInfo // {
        inherit outPath;
      };
      outputs = flake.outputs (inputs // { self = result; });
      result =
        outputs
        // finalSourceInfo
        // {
          inherit inputs outputs;
          sourceInfo = finalSourceInfo;
          _type = "flake";
        };
    in
    result;

  # speed up applyPatches, see:
  # https://github.com/gepbird/nixpkgs-patcher/pull/26
  applyPatchesFast =
    {
      name,
      src,
      patches,
    }:
    stdenvNoCC.mkDerivation {
      inherit name src patches;

      preferLocalBuild = true;
      allowSubstitutes = false;

      phases = [
        "unpackPhase"
        "patchPhase"
        "installPhase"
      ];

      unpackPhase = ''
        runHook preUnpack

        mkdir -p "$out"
        ls -A "$src" | xargs -P "$NIX_BUILD_CORES" -I@ sh -c '
            if [ -d "$0/$1" ] && [ ! -L "$0/$1" ]; then
              mkdir -p "$2/$1"
              (cd "$0/$1" && tar --hard-dereference -cf - .) | (cd "$2/$1" && tar xf -)
            else
              mkdir -p "$(dirname "$2/$1")"
              cp -a "$0/$1" "$2/$1"
            fi' "$src" @ "$out"
        chmod -R u+w "$out"
        cd "$out"

        runHook postUnpack
      '';

      # unpackPhase already put the tree at its final location.
      installPhase = "true";
    };

  patchInputs =
    {
      unpatchedInputs,
      patchesByInputName,
    }:
    lib.mapAttrs (
      name: unpatchedInput:
      patchInput {
        inherit name;
        inherit unpatchedInput;
        patches = patchesByInputName.${name} or [ ];
      }
    ) unpatchedInputs;

  patchInput =
    {
      name,
      unpatchedInput,
      patches,
    }:
    if patches == [ ] then
      unpatchedInput
    else
      importFlake {
        src = applyPatchesFast {
          name = "${name}-patched";
          inherit patches;
          # use builtins.path to handle local `url = path:/PATH` format
          src = builtins.path {
            path = unpatchedInput;
            name = "source";
          };
        };
        inherit (unpatchedInput) inputs;
        sourceInfo = unpatchedInput.sourceInfo or { };
      };
in
{
  inherit fetchpatch fetchpatch2 fetchurl;

  patch =
    unpatchedInputs: patchesByInputName:
    patchInputs {
      inherit unpatchedInputs;
      inherit patchesByInputName;
    };
}
