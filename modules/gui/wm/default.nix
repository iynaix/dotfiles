{
  tags = [ "wm" ];

  config =
    {
      config,
      lib,
      pkgs,
      user,
      ...
    }:
    lib.mkMerge [
      {
        environment = {
          sessionVariables = {
            NIXOS_OZONE_WL = "1";
            QT_QPA_PLATFORM = "wayland";
          };
        };

        xdg.portal = {
          enable = true;
          config = {
            common.default = [ "gnome" ];
            obs.default = [ "gnome" ];
          };
          extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
        };

        hj.files.".face".source = ../../avatar.png;

        custom = {
          programs.print-config = {
            wm = /* sh */ ''
              if [ "$XDG_CURRENT_DESKTOP" == "Hyprland" ]; then
                  hyprland-config
              elif [ "$XDG_CURRENT_DESKTOP" == "niri" ]; then
                  niri-config
              elif [ "$XDG_CURRENT_DESKTOP" == "mango" ]; then
                  mango-config
              fi
            '';
          };
        };
      }

      # autologin
      {
        services.displayManager = {
          autoLogin.user = user;

          # scrolling is nicer for laptop with a smaller screen
          defaultSession = lib.mkDefault "niri";

          ly = {
            enable = true;
            settings = {
              bigclock = "en";
              save = false; # don't use previous successful session
              session_log = "${config.hj.xdg.data.directory}/ly-session.log";
            };
          };
        };

        custom.programs.print-config = {
          ly = /* sh */ ''moor "/etc/ly/config.ini"'';
        };

        # block other ttys from autologin when bypassed from lockscreen
        services.getty.autologinUser = lib.mkIf (!config.custom.lock.enable) user;
      }
    ];
}
