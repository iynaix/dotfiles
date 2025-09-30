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
    mapAttrsToList
    mkOption
    mkOptionType
    mergeOneOption
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
    # automount disks
    programs.dconf.enable = true;
    services.gvfs.enable = true;

    # thanks for not fucking wasting my time
    hjem.clobberByDefault = true;

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
