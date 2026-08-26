{
  tags = [ "wm" ];

  config =
    { config, lib, ... }:
    {
      custom.programs =
        let
          startupArgsByWorkspace =
            config.custom.hardware.monitors
            |> lib.concatMap (
              d:
              lib.imap1 (i: w: {
                "${toString w}" = {
                  default_output = d.name;
                  default_workspace = i;
                };
              }) d.workspaces
            )
            |> lib.mergeAttrsList;
        in
        {
          umbriel.settings = lib.mkMerge (
            config.custom.wm.startup
            |> map (startup: {
              general.autostart = [ startup.spawn ];
              window_rule = lib.optional (startup.app-id != null || startup.title != null) (
                # TODO: { at-startup = true; }
                # lookup workspace number and output from workspace
                startupArgsByWorkspace.${toString startup.workspace}
                // (lib.optionalAttrs (startup.app-id != null) {
                  match.app_id = startup.app-id;
                })
                // (lib.optionalAttrs (startup.title != null) {
                  match.title = startup.title;
                })
              );
            })
          );
        };
    };
}
