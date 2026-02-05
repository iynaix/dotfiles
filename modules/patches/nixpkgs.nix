{ inputs, self, ... }:
{
  # helper to create a patched nixpkgs for system, used for nixos config and flake packages
  flake.libCustom = {
    nixpkgsWithPatchesFor =
      system:
      let
        nixpkgs-bootstrap = import inputs.nixpkgs { inherit system; };
      in
      if self.patches == [ ] then
        inputs.nixpkgs
      else
        nixpkgs-bootstrap.applyPatches {
          name = "nixpkgs-iynaix";
          src = inputs.nixpkgs;
          patches = map (
            patch:
            # attrset for fetchurl
            if builtins.isAttrs patch then
              nixpkgs-bootstrap.fetchpatch patch
            # patch as local file
            else
              patch
          ) self.patches;
        };
  };

  # patches to be applied to nixpkgs
  flake.patches = [
    # orca-slicer 2.3.2-dev
    # https://github.com/NixOS/nixpkgs/pull/480799
    {
      url = "https://github.com/NixOS/nixpkgs/commit/6c08970e09a1f7de80bbdc165c7f9afb8306c027.patch";
      hash = "sha256-gDow7JMMrNgqkRDZVPL9dgPAZCghd4GWI7GBHeteEDo=";
    }
    # actually import the mangowc module
    # remove when https://github.com/NixOS/nixpkgs/pull/484963 is merged
    {
      url = "https://github.com/NixOS/nixpkgs/commit/966fced4f13518621e9d6ed528d2617640c6f315.patch";
      hash = "sha256-ZN55kHhhmwfjZ2QLG00AjGbDV7f7ZRAKD0Fs/sMDUXA=";
    }
  ];
}
