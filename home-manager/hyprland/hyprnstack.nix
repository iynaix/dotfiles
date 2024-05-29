{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.custom.hyprland.enable {
  wayland.windowManager.hyprland = lib.mkIf (config.custom.hyprland.plugin == "hyprnstack") {
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
      workspace = lib.mkAfter (
        lib.flatten (
          pkgs.custom.lib.mapWorkspaces (
            { monitor, workspace, ... }:
            let
              isUltrawide = builtins.div (monitor.width * 1.0) monitor.height > builtins.div 16.0 9;
              stacks = if (monitor.vertical || isUltrawide) then 3 else 2;
            in
            [
              "${workspace},layoutopt:nstack-stacks:${toString stacks}"
              "${workspace},layoutopt:nstack-orientation:${if monitor.vertical then "top" else "left"}"
            ]
          ) config.custom.monitors
        )
      );
    };
  };
}
