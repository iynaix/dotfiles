{
  config,
  user,
  lib,
  ...
}: let
  hm = config.home-manager.users.${user};
in {
  programs.file-roller.enable = true;

  # fix mimetype associations
  xdg.mime.defaultApplications =
    {
      "inode/directory" = "nemo.desktop";
      # wtf zathura registers itself to open archives
      "application/zip" = "org.gnome.FileRoller.desktop";
      "application/vnd.rar" = "org.gnome.FileRoller.desktop";
    }
    // lib.optionalAttrs hm.programs.zathura.enable {
      "application/pdf" = "org.pwmt.zathura.desktop";
    }
    // (lib.optionalAttrs hm.programs.imv.enable
      {
        "image/jpeg" = "imv-dir.desktop";
        "image/gif" = "imv-dir.desktop";
        "image/webp" = "imv-dir.desktop";
        "image/png" = "imv-dir.desktop";
      });

  home-manager.users.${user} = {
    gtk.gtk3.bookmarks = lib.optionals config.iynaix-nixos.hdds.enable [
      "file:///media/6TBRED/Anime/Current Anime Current"
      "file:///media/6TBRED/US/Current TV Current"
      "file:///media/6TBRED/Movies"
    ];
  };
}
