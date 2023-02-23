{ config, pkgs, user, lib, host, ... }:
let displayCfg = config.iynaix.displays; in
{
  imports = [
    ./hardware.nix
  ];

  config = {
    iynaix.displays.monitor1 = "Virtual-1";
    # iynaix.persist.tmpfs.root = true;
    # iynaix.persist.tmpfs.home = true;

    # enable clipboard and file sharing
    services.qemuGuest.enable = true;
    services.spice-vdagentd.enable = true;
    services.spice-webdavd.enable = true;

    # fix for spice-vdagentd not starting in wms
    systemd.user.services.spice-agent = {
      enable = true;
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.spice-vdagent}/bin/spice-vdagent -x";
      };
      unitConfig = {
        ConditionVirtualization = "vm";
        Description = "Spice guest session agent";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };
    };

    home-manager.users.${user} = {
      # disable picom as it lags in vm
      services.picom.enable = lib.mkForce false;

      xsession.windowManager.bspwm = lib.mkIf config.iynaix.bspwm.enable {
        monitors = {
          "${displayCfg.monitor1}" = [ "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" ];
        };
        extraConfigEarly = "xrandr --output '${displayCfg.monitor1}' --mode 1920x1200 --pos 0x0 --rotate normal";
        extraConfig = "xwallpaper --output '${displayCfg.monitor1}' --zoom ${../../modules/desktop/wallpapers/gits-catppuccin-3440.png}";

        # just edit nix config on startup
        startupPrograms = lib.mkForce [
          # vscode on desktop 1
          ''bspc rule -a Code -o desktop="^1"''
          "code"
          # terminal on desktop 2
          ''bspc rule -a Alacritty -o desktop="^2"''
          "$TERMINAL"
          # nemo on desktop 3
          ''bspc rule -a Nemo:nemo -o desktop="^3"''
          "nemo"
        ];
      };

      services.polybar = lib.mkIf config.iynaix.bspwm.enable {
        script = "polybar ${host} &";
      };
    };
  };
}
