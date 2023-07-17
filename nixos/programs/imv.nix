{
  pkgs,
  user,
  ...
}: {
  config = {
    xdg.mime.defaultApplications = {
      "image/jpeg" = "imv-dir.desktop";
      "image/gif" = "imv-dir.desktop";
      "image/webp" = "imv-dir.desktop";
      "image/png" = "imv-dir.desktop";
    };

    home-manager.users.${user} = {
      home.packages = [pkgs.imv];

      xdg.configFile."imv/config".text = ''
        [options]
        overlay = false

        [binds]
        i = overlay
        x = exec rm "$imv_current_file"
        w = exec hypr-wallpaper "$imv_current_file"
        z = zoom actual
      '';
    };

    nixpkgs.overlays = [
      (self: super: {
        # patch imv to not repeat keypresses causing waybar to launch infinitely
        # https://github.com/eXeC64/imv/issues/207#issuecomment-604076888
        imv = super.imv.overrideAttrs (oldAttrs: {
          patches = [./imv-disable-key-repeat-timer.patch];
        });
      })
    ];
  };
}