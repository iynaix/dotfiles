{...}: {
  programs.imv = {
    enable = true;
    settings = {
      options = {
        overlay = false;
      };
      binds = {
        i = "overlay";
        x = "exec rm \"$imv_current_file\"";
        w = "exec hypr-wallpaper \"$imv_current_file\"";
        z = "zoom actual";
      };
    };
  };
}
