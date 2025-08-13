{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
in
mkIf (config.custom.wm != "tty") {
  programs.pqiv = {
    enable = true;
    # fix window resizing on the first image in niri if called in a keybind
    package = pkgs.pqiv.overrideAttrs (o: {
      patches = (o.patches or [ ]) ++ [
        # use the GDK wayland module
        (pkgs.fetchpatch2 {
          url = "https://github.com/phillipberndt/pqiv/commit/3390155a0881ad6180e8b9ae991d1c7dc1141080.patch";
          hash = "sha256-ZsZ7oFSAJl+MuM/ITRcU7jkkRwlPqUKZUkZOvkzhaOs=";
          revert = true;
        })
      ];
    });

    settings = {
      options = {
        box-colors = "#FFFFFF:#000000";
        disable-backends = "archive,archive_cbx,libav,poppler,spectre,wand";
        hide-info-box = 1;
        max-depth = 1;
        window-position = "off";
      };
    };
    extraConfig = ''
      [actions]
      # hide cursor after 1 second inactivity
      set_cursor_auto_hide(1)
      # maintain window size
      toggle_scale_mode(5)

      [keybindings]
      t { montage_mode_enter() }
      w { command(wallpaper $1) }
      x { command(rm $1) }
      y { command(wl-copy $1) }
      z { toggle_scale_mode(0) }
      ? { command(>pqiv --show-bindings) }
      <Left> { goto_file_relative(-1) }
      <Right> { goto_file_relative(1) }
      <Up> { nop() }
      <Down> { nop() }

      @MONTAGE {
        t { montage_mode_return_cancel() }
      }
    '';
  };

  xdg.mimeApps.defaultApplications = {
    "image/jpeg" = "pqiv.desktop";
    "image/gif" = "pqiv.desktop";
    "image/webp" = "pqiv.desktop";
    "image/png" = "pqiv.desktop";
  };
}
