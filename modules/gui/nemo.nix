{
  config,
  lib,
  libCustom,
  pkgs,
  ...
}:
let
  inherit (lib)
    getExe
    gvariant
    mkIf
    optionals
    ;
in
mkIf (config.custom.wm != "tty") {
  environment.systemPackages = with pkgs; [
    p7zip-rar # support for encrypted archives
    nemo-fileroller
    nemo-with-extensions
    webp-pixbuf-loader # for webp thumbnails
  ];

  xdg = {
    # fix opening terminal for nemo / thunar by using xdg-terminal-exec spec
    terminal-exec = {
      enable = true;
      settings = {
        default = [ config.hm.custom.terminal.desktop ];
      };
    };

    # fix mimetype associations
    mime.defaultApplications = {
      "inode/directory" = "nemo.desktop";
      # wtf zathura / pqiv registers themselves to open archives
      "application/zip" = "org.gnome.FileRoller.desktop";
      "application/vnd.rar" = "org.gnome.FileRoller.desktop";
      "application/x-7z-compressed" = "org.gnome.FileRoller.desktop";
      "application/x-bzip2-compressed-tar" = "org.gnome.FileRoller.desktop";
      "application/x-tar" = "org.gnome.FileRoller.desktop";
    };
  };

  custom = {
    dconf.settings = {
      # fix open in terminal
      "org/gnome/desktop/applications/terminal" = {
        exec = getExe config.xdg.terminal-exec.package;
      };
      "org/cinnamon/desktop/applications/terminal" = {
        exec = getExe config.xdg.terminal-exec.package;
      };
      "org/nemo/preferences" = {
        default-folder-viewer = "list-view";
        show-hidden-files = true;
        start-with-dual-pane = true;
        date-format-monospace = true;
        # needs to be a uint64!
        thumbnail-limit = gvariant.mkUint64 (100 * 1024 * 1024); # 100 mb
      };
      "org/nemo/window-state" = {
        sidebar-bookmark-breakpoint = gvariant.mkInt32 0;
        sidebar-width = gvariant.mkInt32 180;
      };
      "org/nemo/preferences/menu-config" = {
        selection-menu-make-link = true;
        selection-menu-copy-to = true;
        selection-menu-move-to = true;
      };
    };

    gtk.bookmarks =
      let
        inherit (libCustom) homePath;
      in
      [
        (homePath "Downloads")
        (homePath "projects")
        (homePath "projects/dotfiles")
        (homePath "projects/nixpkgs")
        (homePath "projects/coinfc Work")
        (homePath "Documents")
        (homePath "Pictures/Wallpapers")
      ]
      ++ optionals config.custom.programs.wallpaper-tools.enable [
        (homePath "Pictures/wallpapers_in Walls In")
      ]
      ++ [
        "/persist Persist"
      ];
  };

  custom.programs.hyprland.settings = {
    # disable transparency for file delete dialog
    windowrule = [ "forcergbx,floating:1,class:(nemo)" ];
  };

  custom.persist = {
    home = {
      directories = [
        # folder preferences such as view mode and sort order
        ".local/share/gvfs-metadata"
      ];
      cache.directories = [
        # thumbnail cache
        ".cache/thumbnails"
      ];
    };
  };
}
