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
  fetchurl,
  applyPatches,
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
    { src, inputs }:
    let
      flake = import (src + "/flake.nix");
      outPath = toString src;
      # I'm not sure what to do with `sourceInfo`. It normally comes from the
      # lockfile [0]. Copying the old value feels wrong.
      # I'm going to opt to leave it unset until something goes wrong.
      #
      # [0]: https://github.com/NixOS/nix/blob/2.29.0/src/libflake/call-flake.nix#L52-L63
      sourceInfo = {
        inherit outPath;
      };
      outputs = flake.outputs (inputs // { self = result; });
      result =
        outputs
        // sourceInfo
        // {
          inherit inputs;
          inherit outputs;
          inherit sourceInfo;
          _type = "flake";
        };
    in
    result;

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
        src = applyPatches {
          name = "${name}-patched";
          inherit patches;
          src = unpatchedInput;
        };
        inherit (unpatchedInput) inputs;
      };
in
{
  inherit fetchpatch fetchurl;

  patch =
    unpatchedInputs: patchesByInputName:
    patchInputs {
      inherit unpatchedInputs;
      inherit patchesByInputName;
    };
}
