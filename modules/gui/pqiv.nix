{ inputs, ... }:
{
  flake.modules.nixos.gui =
    { config, pkgs, ... }:
    let
      pqivConf = ''
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
        c { command(nomacs $1) }
        m { command(mv $1 "${config.hj.directory}/Pictures/wallpapers_in") }
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
    in
    {
      nixpkgs.overlays = [
        (_: prev: {
          # overlay so that dotfiles-rs can pick up wrapped package
          pqiv = inputs.wrappers.lib.wrapPackage {
            pkgs = prev;
            package = prev.pqiv;
            env.PQIVRC_PATH = pkgs.writeText "pqivrc" pqivConf;
          };
        })
      ];

      environment.systemPackages = with pkgs; [
        pqiv # overlay-ed above
        nomacs
      ];

      xdg.mime.defaultApplications = {
        "image/jpeg" = "pqiv.desktop";
        "image/gif" = "pqiv.desktop";
        "image/webp" = "pqiv.desktop";
        "image/png" = "pqiv.desktop";
      };

      custom.persist = {
        home = {
          directories = [
            ".config/nomacs"
          ];
        };
      };
    };
}
