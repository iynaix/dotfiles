{ pkgs, user, ... }: {
  programs.file-roller.enable = true;
  xdg.mime.defaultApplications = {
    "inode/directory" = "nemo.desktop";
    # wtf zathura registers itself to open zip files
    "application/zip" = "org.gnome.FileRoller.desktop";
  };

  home-manager.users.${user} = {
    home = {
      packages = with pkgs; [
        cinnamon.nemo-with-extensions
        cinnamon.nemo-fileroller
        gzip
        rar
      ];
    };

    gtk.gtk3.bookmarks = [
      "file:///home/iynaix/Downloads"
      "file:///home/iynaix/projects"
      "file:///home/iynaix/projects/dotfiles"
      "file:///home/iynaix/projects/coinfc"
      "file:///home/iynaix/Pictures"
      "file:///persist Persist"
    ];

    dconf.settings = {
      # fix open in terminal
      "org/gnome/desktop/applications/terminal" = {
        exec = "kitty";
      };
      "org/cinnamon/desktop/applications/terminal" = {
        exec = "kitty";
      };
      "org/nemo/preferences" = {
        default-folder-viewer = "list-view";
        show-hidden-files = true;
        start-with-dual-pane = true;
        date-format-monospace = true;
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
  };

}
