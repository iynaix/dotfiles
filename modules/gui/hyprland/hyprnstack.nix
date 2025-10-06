{
  config,
  lib,
  libCustom,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    mkAfter
    mkIf
    optionals
    ;
in
mkIf (config.custom.wm == "hyprland") {
  custom.programs.hyprland =
    if config.custom.programs.hyprnstack.enable then
      {
        plugins = [ pkgs.custom.hyprnstack ];

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
            libCustom.mapWorkspaces (
              { monitor, workspace, ... }:
              let
                isUltrawide = builtins.div (monitor.width * 1.0) monitor.height > builtins.div 16.0 9;
                stacks = if (monitor.isVertical || isUltrawide) then 3 else 2;
              in
              concatStringsSep "," (
                [
                  workspace
                  "layoutopt:nstack-stacks:${toString stacks}"
                  "layoutopt:nstack-orientation:${if monitor.isVertical then "top" else "left"}"
                ]
                ++ optionals (!isUltrawide) [ "layoutopt:nstack-mfact:0.0" ]
              )
            ) config.custom.hardware.monitors
          );
        };
      }

    # handle workspace orientation without hyprnstack
    else
      {
        settings.workspace = mkAfter (
          libCustom.mapWorkspaces (
            { monitor, workspace, ... }:
            "${workspace},layoutopt:orientation:${if (monitor.isVertical != 0) then "top" else "left"}"
          ) config.custom.hardware.monitors
        );
      };
}
