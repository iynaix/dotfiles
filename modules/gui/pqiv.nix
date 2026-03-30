{
  lib,
  self,
  ...
}:
let
  pqivOptions = {
    options = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Contents under [options] section of pqiv config file";
    };

    actions = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Contents under [actions] section of pqiv config file";
    };

    keybindings = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Contents under [keybindings] section of pqiv config file";
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra config to add to pqiv config file";
    };
  };
in
{
  flake.wrappers.pqiv =
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
      imports = [ wlib.modules.default ];

      options = pqivOptions // {
        pqivrc = lib.mkOption {
          type = wlib.types.file config.pkgs;
          default.content = pqivConf;
          visible = false;
        };
      };

      config.package = lib.mkDefault config.pkgs.pqiv;
      config.env.PQIVRC_PATH = toString config.pqivrc.path;
    };

  # expose generic pqiv package without local paths
  perSystem =
    { pkgs, ... }:
    {
      packages.pqiv = self.wrappers.pqiv.wrap { inherit pkgs; };
    };

  flake.modules.nixos.gui =
    { config, pkgs, ... }:
    {
      nixpkgs.overlays = [
        (_: prev: {
          pqiv = self.wrappers.pqiv.wrap {
            pkgs = prev;
            keybindings = ''
              c { command(nomacs $1) }
              w { command(wallpaper $1) }
              m { command(mv $1 "${config.hj.directory}/Pictures/wallpapers_in") }
              <Control>m { command(mv $1 "${config.hj.directory}/Pictures/wallpapers_crop") }
            '';
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

      custom.programs.print-config = {
        pqiv = /* sh */ ''moor "${pkgs.pqiv.configuration.env.PQIVRC_PATH.data}"'';
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
