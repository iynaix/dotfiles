{
  config,
  isNixOS,
  lib,
  pkgs,
  ...
}: {
  home = {
    packages = with pkgs; [
      cinnamon.nemo-with-extensions
      cinnamon.nemo-fileroller
      config.custom.terminal.fakeGnomeTerminal
    ];
  };

  xdg = {
    # fix mimetype associations
    mimeApps = {
      enable = true;
      defaultApplications =
        {
          "inode/directory" = "nemo.desktop";
          # wtf zathura registers itself to open archives
          "application/zip" = "org.gnome.FileRoller.desktop";
          "application/vnd.rar" = "org.gnome.FileRoller.desktop";
          "application/x-7z-compressed" = "org.gnome.FileRoller.desktop";
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

    # other OSes seem to override this file
    configFile = lib.mkIf (!isNixOS) {
      "mimeapps.list".force = true;
      "gtk-3.0/bookmarks".force = true;
    };
  };

  gtk.gtk3.bookmarks = let
    homeDir = config.home.homeDirectory;
  in [
    "file://${homeDir}/Downloads"
    "file://${homeDir}/projects"
    "file://${homeDir}/projects/dotfiles"
    "file://${homeDir}/projects/coinfc"
    "file://${homeDir}/Pictures/Wallpapers"
    "file:///persist Persist"
  ];

  dconf.settings = {
    # fix open in terminal
    "org/gnome/desktop/applications/terminal" = {
      exec = lib.getExe config.custom.terminal.package;
    };
    "org/cinnamon/desktop/applications/terminal" = {
      exec = lib.getExe config.custom.terminal.package;
    };
    "org/nemo/preferences" = {
      default-folder-viewer = "list-view";
      show-hidden-files = true;
      start-with-dual-pane = true;
      date-format-monospace = true;
      # needs to be a uint64!
      thumbnail-limit = lib.hm.gvariant.mkUint64 (100 * 1024 * 1024); # 100 mb
    };
    "org/nemo/window-state" = {
      sidebar-bookmark-breakpoint = 0;
      sidebar-width = 180;
    };
    "org/nemo/preferences/menu-config" = {
      selection-menu-make-link = true;
      selection-menu-copy-to = true;
      selection-menu-move-to = true;
    };
  };

  custom.persist = {
    home.directories = [
      # folder preferences such as view mode and sort order
      ".local/share/gvfs-metadata"
    ];
    cache = [
      # thumbnail cache
      ".cache/thumbnails"
    ];
  };
}
