{
  inputs,
  lib,
  self,
  ...
}:
{
  imports = [ inputs.flake-parts.flakeModules.modules ];

  systems = [
    # systems for which you want to build the `perSystem` attributes
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ];

  perSystem =
    { system, ... }:
    let
      nixpkgs-patched = self.libCustom.nixpkgsWithPatchesFor system;
      pkgs = import nixpkgs-patched {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      # initialize the pkgs for perSystem to be the patched nixpkgs
      _module.args = { inherit pkgs; };

      formatter = pkgs.nixfmt;
      packages = (import ../packages) { inherit inputs pkgs; };
    };

  # expose top level flake options
  flake.options = {
    patches = lib.mkOption {
      type = lib.types.anything;
      default = [ ];
      description = "Patches to be applied onto nixpkgs";
    };

    wrapperModules = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Wrapper modules";
    };

    libCustom = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Custom library functions / utilities";
    };
  };
}
