{pkgs, ...}: {
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
}
