{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkOption types;
in
{
  options.custom = {
    programs.pqiv.settings = mkOption {
      type = types.lines;
      default = "";
      description = "Settings for pqiv";
    };
  };

  config = mkIf (config.custom.wm != "tty") {
    # custom.wrappers = [
    #   (_: _prev: {
    #     pqiv = {
    #       env.PQIVRC_PATH = pkgs.writeText "pqivrc" config.custom.programs.pqiv.settings;
    #     };
    #   })
    # ];

    # TODO: remove when wrappers patches desktop files
    environment.etc."xdg/pqivrc".text = config.custom.programs.pqiv.settings;

    custom.programs.pqiv.settings = ''
      [options]
      box-colors = #FFFFFF:#000000
      disable-backends = archive,archive_cbx,libav,poppler,spectre,wand
      hide-info-box = 1
      max-depth = 1
      window-position = off

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

    environment.systemPackages = [ pkgs.pqiv ];

    xdg.mime.defaultApplications = {
      "image/jpeg" = "pqiv.desktop";
      "image/gif" = "pqiv.desktop";
      "image/webp" = "pqiv.desktop";
      "image/png" = "pqiv.desktop";
    };
  };
}
