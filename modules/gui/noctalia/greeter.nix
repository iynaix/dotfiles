{
  tags = [ "gui" ];

  config =
    {
      config,
      user,
      ...
    }:
    {
      # NOTE: using patches to the nixos module for autologin, default session and noctalia sync
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

            user.default = user;
            idle.timeout = 60;
          };

          # sync with noctalia wallpaper and colors
          passwordlessSyncUsers = [ user ];
        };
      };
    };
}
