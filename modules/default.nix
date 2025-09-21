{
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (lib)
    isFunction
    literalExpression
    mkOption
    mkOptionType
    mergeOneOption
    ;
  inherit (lib.types) listOf;
  overlayType = mkOptionType {
    name = "custom-wrapper-module";
    description = "Custom wrapper module";
    check = isFunction;
    merge = mergeOneOption;
  };
in
{
  options.custom = {
    wrappers = mkOption {
      default = [ ];
      example = literalExpression ''
        [
          ({pkgs, ...}: {
            wrappers.helix = {
              basePackage = pkgs.helix;
              prependFlags = [ "-c" ./config.toml ];
            };
          })
        ]
      '';
      type = listOf overlayType;
      description = ''
        List of wrappers to apply to Nixpkgs.
      '';
    };
  };

  config = {
    # apply all the packages as overlays, so they can be easily referenced by other modules
    nixpkgs.overlays = [
      (
        _: prev:
        let
          evald = inputs.wrapper-manager.lib {
            pkgs = prev;
            modules = config.custom.wrappers;
          };
        in
        builtins.mapAttrs (_: value: value.wrapped) evald.config.wrappers
      )
    ];
  };
}
