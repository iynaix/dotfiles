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
      patchSpecByInputName,
    }:
    lib.mapAttrs (
      name: unpatchedInput:
      patchInput {
        inherit name;
        inherit unpatchedInput;
        patchSpec = patchSpecByInputName.${name} or { };
      }
    ) unpatchedInputs;

  patchInput =
    {
      name,
      unpatchedInput,
      patchSpec,
    }:
    let
      patchSpecByInputName = patchSpec.inputs or { };
      patches = patchSpec.patches or [ ];

      patchedInputs = patchInputs {
        unpatchedInputs = unpatchedInput.inputs;
        inherit patchSpecByInputName;
      };

      patchedSrc =
        if patches == [ ] then
          unpatchedInput
        else
          applyPatches {
            name = "${name}-patched";
            inherit patches;
            src = unpatchedInput;
          };
    in
    if patchSpecByInputName == { } && patches == [ ] then
      unpatchedInput
    else
      importFlake {
        src = patchedSrc;
        inputs = patchedInputs;
      };
in

{
  inherit fetchpatch fetchurl;
  patch =
    unpatchedInputs: patchSpecByInputName:
    patchInputs {
      inherit unpatchedInputs;
      inherit patchSpecByInputName;
    };
}
