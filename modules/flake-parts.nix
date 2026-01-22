{ inputs, lib, ... }:
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
    { pkgs, ... }:
    {
      formatter = pkgs.nixfmt;
      packages = (import ../packages) { inherit inputs pkgs; };
    };

  # expose wrapperModules as top level flake option
  flake.options.patches = lib.mkOption {
    type = lib.types.anything;
    default = [ ];
    description = "Patches to be applied onto nixpkgs";
  };

  # expose wrapperModules as top level flake option
  flake.options.wrapperModules = lib.mkOption {
    type = lib.types.attrs;
    default = { };
    description = "Wrapper modules";
  };

  flake.options.libCustom = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    default = { };
    description = "Library functions / utilities";
  };
}
