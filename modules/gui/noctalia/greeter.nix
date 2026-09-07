{
  tags = [ "gui" ];

  config =
    {
      config,
      user,
      ...
    }:
    {
      services.displayManager = {
        noctalia-greeter = {
          enable = true;

          cursorTheme = {
            inherit (config.custom.gtk.cursor)
              name
              package
              ;
          };

          settings = {
            appearance = {
              hide_logo = true;
              password_style = "random";
              scheme_selector_position = "hidden"; # using synced settings from noctalia, unnecessary
            };

            session.default = config.services.displayManager.defaultSession;
            user.default = user;
            idle.timeout = 60;
          };
        };
      };

      # sync with noctalia's settings, password prompt will continue until noctalia-greeter v1.5.0
      # https://docs.noctalia.dev/greeter/sync/?section=nixos#nixos
      security.polkit = {
        enablePkexecWrapper = true;
        extraConfig = /* js */ ''
          polkit.addRule(function(action, subject) {
            var allowedUsers = ["${user}"];
            if (action.id == "org.noctalia.greeter.sync-appearance" &&
                action.lookup("program") == "${config.services.displayManager.noctalia-greeter.package}/bin/noctalia-greeter-apply-appearance" &&
                action.lookup("user") == "root" &&
                subject.local && subject.active &&
                allowedUsers.indexOf(subject.user) >= 0) {
              return polkit.Result.YES;
            }
          });
        '';
      };

      custom.persist = {
        root = {
          directories = [
            # greeter wallpaper and settings synced from noctalia
            "/var/lib/noctalia-greeter"
          ];
        };
      };
    };
}
