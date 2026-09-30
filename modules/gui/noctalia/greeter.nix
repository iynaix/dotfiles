{
  tags = [ "gui" ];

  config =
    {
      config,
      lib,
      user,
      ...
    }:
    {
      # block other ttys from autologin when bypassed from lockscreen
      services.getty.autologinUser = lib.mkIf (!config.custom.lock.enable) user;

      # NOTE: using patches to the nixos module for autologin, default session
      services.displayManager = {
        autoLogin.user = user;

        defaultSession = lib.mkDefault "umbriel";

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

            user.default = user;
            idle.timeout = 60;
          };

          # sync with noctalia wallpaper and colors
          passwordlessSyncUsers = [ user ];
        };
      };
    };
}
