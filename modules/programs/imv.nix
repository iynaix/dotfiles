{
  pkgs,
  user,
  config,
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

      xdg.configFile."imv/config".text =
        /*
        ini
        */
        ''
          [options]
          overlay = true

          [binds]
          i = overlay
          x = exec rm "$imv_current_file"
          w = exec hypr-wallpaper "$imv_current_file"
        '';
    };
  };
}
