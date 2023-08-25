{...}: {
  programs.imv = {
    enable = true;
    settings = {
      options = {
        overlay = false;
      };
      binds = {
        i = "overlay";
        m = "exec mv \"$imv_current_file\" ~/Pictures/Wallpapers";
        x = "exec rm \"$imv_current_file\"";
        w = "exec hypr-wallpaper \"$imv_current_file\"";
        z = "zoom actual";
      };
    };
  };
}
