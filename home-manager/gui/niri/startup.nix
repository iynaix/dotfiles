{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    getExe
    mkIf
    ;
  braveExe = getExe config.programs.chromium.package;

  inherit (config.custom) monitors;
  mon1 = (lib.head monitors).name;
in
mkIf (config.custom.wm == "niri") {
  custom = {
    autologinCommand = "niri-session";
  };

  programs.niri.settings = {
    spawn-at-startup = [
      # browsers
      {
        command = [
          braveExe
          "--profile-directory=Default"
        ];
      }
      {
        command = [
          braveExe
          "--incognito"
        ];
      }

      # # file manager
      # {
      #   command = [ "nemo" ];
      # }

      # # terminal
      # {
      #   command = [ (getExe config.custom.terminal.package) ];
      # }

      # # librewolf for discord
      # { command = [ (getExe config.programs.librewolf.package) ]; }

      # # download related
      # {
      #   command = [
      #     config.custom.terminal.exec
      #     "nvim"
      #     "${config.xdg.userDirs.desktop}/yt.txt"
      #   ];
      # }
      # { command = [ (getExe config.custom.terminal.package) ]; }

      # # misc
      # # fix gparted "cannot open display: :0" error
      # {
      #   command = [
      #     xhostExe
      #     "+local:${user}"
      #   ];
      # }
      # # fix Authorization required, but no authorization protocol specified error
      # {
      #   command = [
      #     xhostExe
      #     "si:localuser:root"
      #   ];
      # }
    ];

    window-rules = [
      {
        matches = [
          {
            app-id = "^brave-browser$";
            at-startup = true;
          }
        ];
        open-on-output = mon1;
      }
      # {
      #   matches = [
      #     {
      #       app-id = "^nemo$";
      #       at-startup = true;
      #     }
      #   ];
      #   open-on-output = mon1;
      #   open-on-workspace = "2";
      # }
    ];
  };

  # start a separate swww service in a different namespace for niri backdrop
  systemd.user.services = {
    swww-backdrop = {
      Install = {
        WantedBy = [ config.wayland.systemd.target ];
      };

      Unit = {
        ConditionEnvironment = "WAYLAND_DISPLAY";
        Description = "swww-daemon-backdrop";
        After = [ config.wayland.systemd.target ];
        PartOf = [ config.wayland.systemd.target ];
      };

      Service = {
        ExecStart = "${lib.getExe' config.services.swww.package "swww-daemon"} --namespace backdrop";
        Restart = "always";
        RestartSec = 10;
      };
    };

    # wallpaper needs both swww daemons running
    wallpaper = {
      Unit = {
        After = [ "swww-backdrop.service" ];
        Requires = [ "swww-backdrop.service" ];
      };
    };
  };
}
