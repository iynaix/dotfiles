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

    # Enable TLP (better than gnomes internal power manager)
    services.tlp = {
      enable = true;
      settings = {
        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 0;
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      };
    };

    # Disable GNOMEs power management
    services.power-profiles-daemon.enable = false;

    # Enable powertop
    powerManagement.powertop.enable = lib.mkForce true;

    # Enable thermald (only necessary if on Intel CPUs)
    services.thermald.enable = true;

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
