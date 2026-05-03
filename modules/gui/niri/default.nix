{
  inputs,
  lib,
  ...
}:
{
  flake.modules.nixos.core = {
    options.custom = {
      programs.niri = {
        # copied from nix-wrapper-modules
        settings = lib.mkOption {
          default = { };
          type = lib.types.submodule {
            freeformType = lib.types.attrs;
            options = {
              binds = lib.mkOption {
                default = { };
                type = lib.types.attrs;
              };
              layout = lib.mkOption {
                default = { };
                type = lib.types.attrs;
              };
              spawn-at-startup = lib.mkOption {
                default = [ ];
                type = lib.types.listOf (lib.types.either lib.types.str (lib.types.listOf lib.types.str));
              };
              spawn-sh-at-startup = lib.mkOption {
                default = [ ];
                type = lib.types.listOf lib.types.str;
              };
              window-rules = lib.mkOption {
                default = [ ];
                type = lib.types.listOf lib.types.attrs;
              };
              layer-rules = lib.mkOption {
                default = [ ];
                type = lib.types.listOf lib.types.attrs;
              };
              workspaces = lib.mkOption {
                default = { };
                type = lib.types.attrsOf (lib.types.nullOr lib.types.anything);
              };
              outputs = lib.mkOption {
                default = { };
                type = lib.types.attrs;
              };
              # change to lines to allow merging
              extraConfig = lib.mkOption {
                default = "";
                type = lib.types.lines;
              };
            };
          };
        };
      };
    };
  };

  flake.modules.nixos.wm =
    { config, pkgs, ... }:
    let
      niri' = inputs.wrappers.wrappers.niri.wrap {
        inherit pkgs;
        package = lib.mkForce (
          pkgs.niri.overrideAttrs (o: {
            doInstallCheck = false; # disable annoying version check

            patches = (o.patches or [ ]) ++ [
              # unmerged PR to fix this
              # https://github.com/YaLTeR/niri/pull/3004
              ./transparent-fullscreen.patch
            ];

            doCheck = false; # faster builds
          })
        );

        v2-settings = true;

        inherit (config.custom.programs.niri) settings;
      };
    in
    {
      environment = {
        shellAliases = {
          niri-log = ''journalctl --user -u niri --no-hostname -o cat | awk '{$1=""; print $0}' | sed 's/^ *//' | sed 's/\x1b[[0-9;]*m//g' '';
        };
      };

      # NOTE: named workspaces are used, because dynamic workspaces are just... urgh
      programs.niri = {
        enable = true;
        package = niri';
        useNautilus = false;
      };

      xdg.portal = {
        config = {
          niri = {
            "org.freedesktop.impl.portal.FileChooser" = "gtk";
          };
        };
      };

      custom.programs = {
        ghostty.extraSettings = {
          background-opacity = lib.mkForce 0.95;
        };

        print-config = {
          # use cat as kdlfmt tries to write the file in the nix store
          niri = /* sh */ ''cat "${niri'.configuration.constructFiles.generatedConfig.outPath}" "${config.hj.xdg.config.directory}/niri/config.kdl" "${config.hj.xdg.config.directory}/niri/noctalia.kdl" | ${lib.getExe pkgs.kdlfmt} format - | moor --lang kdl'';
        };
      };
    };
}
