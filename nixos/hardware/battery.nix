# better battery lif on nixos, see:
# https://www.youtube.com/watch?v=pmuubmFcKtg
{
  config,
  lib,
  ...
}: let
  cfg = config.iynaix-nixos.battery;
in {
  config = lib.mkIf cfg.enable {
    # Better scheduling for CPU cycles
    services.system76-scheduler.settings.cfsProfiles.enable = true;

    hm = {...} @ hmCfg: {
      # add battery indicator to waybar
      iynaix.waybar = lib.mkIf hmCfg.config.iynaix.waybar.enable {
        config.battery = {
          format = "{icon}  {capacity}%";
          format-charging = "  {capacity}%";
          format-icons = ["" "" "" "" ""];
          states = {
            critical = 20;
          };
          tooltip = false;
        };
      };
    };
  };
}
