{
  inputs,
  lib,
  self,
  ...
}:
let
  inherit (lib) mkOption;
  pqivOptions = {
    options = mkOption {
      type = lib.types.lines;
      default = "";
      description = "Contents under [options] section of pqiv config file";
    };

    actions = mkOption {
      type = lib.types.lines;
      default = "";
      description = "Contents under [actions] section of pqiv config file";
    };

    keybindings = mkOption {
      type = lib.types.lines;
      default = "";
      description = "Contents under [keybindings] section of pqiv config file";
    };

    extraConfig = mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra config to add to pqiv config file";
    };
  };
in
{
  flake.wrapperModules.pqiv = inputs.wrappers.lib.wrapModule (
    { config, wlib, ... }:
    let
      pqivConf = ''
        [options]
        box-colors = #FFFFFF:#000000
        disable-backends = archive,archive_cbx,libav,poppler,spectre,wand
        hide-info-box = 1
        max-depth = 1
        window-position = off
        ${config.options}

        [actions]
        # hide cursor after 1 second inactivity
        set_cursor_auto_hide(1)
        # maintain window size
        toggle_scale_mode(5)
        ${config.actions}

        [keybindings]
        t { montage_mode_enter() }
        x { command(rm $1) }
        y { command(wl-copy $1) }
        z { toggle_scale_mode(0) }
        ? { command(>pqiv --show-bindings) }
        <Left> { goto_file_relative(-1) }
        <Right> { goto_file_relative(1) }
        <Up> { nop() }
        <Down> { nop() }
        ${config.keybindings}

        @MONTAGE {
          t { montage_mode_return_cancel() }
        }
        ${config.extraConfig}
      '';
    in
    {
      options = pqivOptions // {
        pqivrc = lib.mkOption {
          type = wlib.types.file config.pkgs;
          default.content = pqivConf;
          visible = false;
        };
      };

      config.package = config.pkgs.pqiv;
      # force wayland, it behaves weird when run through a niri keybind otherwise
      # config.env.GDK_BACKEND = "wayland";
      config.env.PQIVRC_PATH = toString config.pqivrc.path;
    }
  );

  # expose generic pqiv package without local paths
  perSystem =
    { pkgs, ... }:
    {
      packages.pqiv' = (self.wrapperModules.pqiv.apply { inherit pkgs; }).wrapper;
    };

  flake.nixosModules.gui =
    { config, pkgs, ... }:
    {
      nixpkgs.overlays = [
        (_: prev: {
          # overlay so that dotfiles-rs can pick up wrapped package
          pqiv =
            (self.wrapperModules.pqiv.apply {
              pkgs = prev;
              keybindings = ''
                c { command(nomacs $1) }
                w { command(wallpaper $1) }
                m { command(mv $1 "${config.hj.directory}/Pictures/wallpapers_in") }
              '';
            }).wrapper;
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
