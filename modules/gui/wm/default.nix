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

        custom = {
          programs.print-config = {
            wm = /* sh */ ''
              if [ "$XDG_CURRENT_DESKTOP" == "Hyprland" ]; then
                  hyprland-config
              elif [ "$XDG_CURRENT_DESKTOP" == "umbriel" ]; then
                  umbriel-config
              fi
            '';
          };
        };
      }

      # autologin
      {
        services.displayManager = {
          autoLogin.user = user;

          defaultSession = lib.mkDefault "umbriel";
        };

        # block other ttys from autologin when bypassed from lockscreen
        services.getty.autologinUser = lib.mkIf (!config.custom.lock.enable) user;
      }
    ];
}
