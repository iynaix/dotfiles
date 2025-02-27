{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    mkAfter
    mkIf
    mkMerge
    optionals
    ;
in
mkIf config.custom.hyprland.enable (mkMerge [
  (mkIf (config.custom.hyprland.plugin == "hyprnstack") {
    wayland.windowManager.hyprland = {
      plugins = [
        # always build with actual hyprland to keep versions in sync
        (pkgs.custom.hyprnstack.override { hyprland = config.wayland.windowManager.hyprland.package; })
      ];

      settings = {
        general.layout = "nstack";
        "plugin:nstack" = {
          layout = {
            new_is_master = 0;
            # disable smart gaps
            no_gaps_when_only = 0;
            # master is the same size as the stacks
            mfact = 0.0;
          };
        };

        # add rules for vertical displays and number of stacks
        workspace = mkAfter (
          lib.custom.mapWorkspaces (
            { monitor, workspace, ... }:
            let
              isUltrawide = builtins.div (monitor.width * 1.0) monitor.height > builtins.div 16.0 9;
              stacks = if ((monitor.transform != 0) || isUltrawide) then 3 else 2;
            in
            concatStringsSep "," (
              [
                workspace
                "layoutopt:nstack-stacks:${toString stacks}"
                "layoutopt:nstack-orientation:${if (monitor.transform != 0) then "top" else "left"}"
              ]
              ++ optionals (!isUltrawide) [ "layoutopt:nstack-mfact:0.0" ]
            )
          ) config.custom.monitors
        );
      };
    };
  })

  # handle workspace orientation without hyprnstack
  (mkIf (config.custom.hyprland.plugin != "hyprnstack") {
    wayland.windowManager.hyprland.settings.workspace = mkAfter (
      lib.custom.mapWorkspaces (
        { monitor, workspace, ... }:
        "${workspace},layoutopt:orientation:${if (monitor.transform != 0) then "top" else "left"}"
      ) config.custom.monitors
    );
  })
])
