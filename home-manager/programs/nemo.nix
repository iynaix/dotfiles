{
  pkgs,
  config,
  lib,
  isNixOS,
  ...
}: {
  home = {
    packages = with pkgs; [
      cinnamon.nemo-with-extensions
      cinnamon.nemo-fileroller
    ];
  };

  # fix mimetype associations
  xdg.mimeApps = {
    enable = true;
    defaultApplications =
      {
        "inode/directory" = "nemo.desktop";
        # wtf zathura registers itself to open archives
        "application/zip" = "org.gnome.FileRoller.desktop";
        "application/vnd.rar" = "org.gnome.FileRoller.desktop";
      }
      // lib.optionalAttrs config.programs.zathura.enable {
        "application/pdf" = "org.pwmt.zathura.desktop";
      }
      // (lib.optionalAttrs config.programs.imv.enable
        {
          "image/jpeg" = "imv-dir.desktop";
          "image/gif" = "imv-dir.desktop";
          "image/webp" = "imv-dir.desktop";
          "image/png" = "imv-dir.desktop";
        });
  };

  gtk.gtk3.bookmarks = [
    "file:///home/iynaix/Downloads"
    "file:///home/iynaix/projects"
    "file:///home/iynaix/projects/dotfiles"
    "file:///home/iynaix/projects/coinfc"
    "file:///home/iynaix/Pictures"
    "file:///persist Persist"
  ];

  # other OSes seem to override this file
  xdg.configFile."mimeapps.list".force = !isNixOS;
  xdg.configFile."gtk-3.0/bookmarks".force = !isNixOS;

  dconf.settings = {
    # fix open in terminal
    "org/gnome/desktop/applications/terminal" = {
      exec = config.iynaix.terminal.exec;
    };
    "org/cinnamon/desktop/applications/terminal" = {
      exec = config.iynaix.terminal.exec;
    };
    "org/nemo/preferences" = {
      default-folder-viewer = "list-view";
      show-hidden-files = true;
      start-with-dual-pane = true;
      date-format-monospace = true;
      thumnail-limit = 31457280;
    };
    "org/nemo/window-state" = {
      sidebar-bookmark-breakpoint = 0;
    };
    "org/nemo/preferences/menu-config" = {
      selection-menu-make-link = true;
      selection-menu-copy-to = true;
      selection-menu-move-to = true;
    };
  };
}
