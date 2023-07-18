{
  pkgs,
  config,
  lib,
  ...
}: {
  home = {
    packages = with pkgs; [
      cinnamon.nemo-with-extensions
      cinnamon.nemo-fileroller
      gzip
      rar
    ];
  };

  gtk.gtk3.bookmarks =
    [
      "file:///home/iynaix/Downloads"
      "file:///home/iynaix/projects"
      "file:///home/iynaix/projects/dotfiles"
      "file:///home/iynaix/projects/coinfc"
      "file:///home/iynaix/Pictures"
      "file:///persist Persist"
    ]
    ++ lib.optionals config.iynaix.hdds.enable [
      "file:///media/6TBRED/Anime/Current Anime Current"
      "file:///media/6TBRED/US/Current TV Current"
      "file:///media/6TBRED/Movies"
    ];

  dconf.settings = {
    # fix open in terminal
    "org/gnome/desktop/applications/terminal" = {
      exec = lib.getExe config.iynaix.terminal.package;
    };
    "org/cinnamon/desktop/applications/terminal" = {
      exec = lib.getExe config.iynaix.terminal.package;
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
