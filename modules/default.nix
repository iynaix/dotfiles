{
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (lib)
    hasAttr
    isDerivation
    isFunction
    literalExpression
    mapAttrs
    mapAttrsToList
    mkAfter
    mkOption
    mkOptionType
    mergeOneOption
    optionalAttrs
    ;
  inherit (lib.types) attrsOf listOf str;
  overlayType = mkOptionType {
    name = "custom-wrapper-module";
    description = "Custom wrapper module";
    check = isFunction;
    merge = mergeOneOption;
  };
in
{
  options.custom = {
    symlinks = mkOption {
      type = attrsOf str;
      default = { };
      description = "Symlinks to create in the format { dest = src;}";
    };

    wrappers = mkOption {
      default = [ ];
      example = literalExpression ''
        [
          (_: prev: {
            helix = {
              package = prev
              flags = { "-c" = ./config.toml; };
            };
          })
        ]
      '';
      type = listOf overlayType;
      description = ''
        List of overlay functions producing wrapper arguments that will be passed to wrappers.lib.wrapPackage.
        If the `package` argument is omitted, it will be assumed to have the same name as the key.
      '';
    };

  };

  config = {
    # automount disks
    programs.dconf.enable = true;
    services.gvfs.enable = true;

    # thanks for not fucking wasting my time
    hjem.clobberByDefault = true;

    # apply all the packages as overlays, so they can be easily referenced by other modules
    # mkAfter is used so wrappers will be applied after the source overlays in overlays/default.nix
    nixpkgs.overlays = mkAfter (
      map (
        wrapper:
        (
          final: prev:
          let
            packagesToWrap = wrapper final prev;
          in
          mapAttrs (
            pkgName: wrapperArgs:
            if isDerivation wrapperArgs then
              wrapperArgs
            else
              inputs.wrappers.lib.wrapPackage (
                {
                  pkgs = prev;
                }
                // (optionalAttrs (hasAttr pkgName prev) {
                  package = prev.${pkgName}; # default to the package of the same name
                })
                // wrapperArgs
              )
          ) packagesToWrap
        )
      ) config.custom.wrappers
    );

    # create symlink to dotfiles from /etc/nixos
    custom.symlinks = {
      "/etc/nixos" = "/persist${config.hj.directory}/projects/dotfiles";
    };

    # create symlinks
    systemd.tmpfiles.rules = [
      # cleanup systemd coredumps once a week
      "D! /var/lib/systemd/coredump root root 7d"
    ]
    ++ (mapAttrsToList (dest: src: "L+ ${dest} - - - - ${src}") config.custom.symlinks);
  };
}
