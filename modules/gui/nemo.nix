{
  flake.nixosModules.gui =
    {
      config,
      host,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) gvariant optionals;
    in
    {
      environment.systemPackages = with pkgs; [
        file-roller
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
            default = [ config.custom.programs.terminal.desktop ];
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

      # add a custom "open in terminal" option to the context menu
      hj.xdg.data.files."nemo/actions/open-in-ghostty.nemo_action".text = ''
        [Nemo Action]
        Name=Open in Terminal
        Comment=Open a terminal in this location
        Exec=ghostty --working-directory=%F
        Icon-Name=utilities-terminal
        Selection=Any
        Extensions=dir;
      '';

      custom = {
        dconf.settings = {
          # fix open in terminal
          "org/gnome/desktop/default-applications/terminal" = {
            exec = "xdg-terminal-exec";
          };
          "org/cinnamon/desktop/default-applications/terminal" = {
            exec = "xdg-terminal-exec";
          };
          "org/nemo/list-view" = {
            default-visible-columns = [
              "name"
              "size"
              "mime_type"
              "date_modified"
            ];
            enable-folder-expansion = true;
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
            # hide the default "open in terminal options" to use the custom one
            background-menu-open-in-terminal = false;
            selection-menu-open-in-terminal = false;
          };
        };

        gtk.bookmarks = [
          "${config.hj.directory}/Downloads"
          "${config.hj.directory}/projects"
          "${config.hj.directory}/projects/dotfiles"
          "${config.hj.directory}/projects/nixpkgs"
          "${config.hj.directory}/projects/coinfc Work"
          "${config.hj.directory}/Documents"
          "${config.hj.directory}/Pictures/Wallpapers"
        ]
        ++ optionals (host == "desktop") [
          "${config.hj.directory}/Pictures/wallpapers_in Walls In"
        ]
        ++ [
          "/persist Persist"
        ];
      };

      custom.programs.hyprland.settings = {
        # disable transparency for file delete dialog
        windowrule = [ "match:class nemo match:float forcergbx" ];
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
    };
}
