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
    getExe'
    isBool
    isString
    mapAttrs'
    mkIf
    mkMerge
    nameValuePair
    ;
  opacity = "E5"; # 90%
  # see home-manager for original implementation
  # https://github.com/nix-community/home-manager/blob/master/modules/services/dunst.nix
  toDunstIni = lib.generators.toINI {
    mkKeyValue =
      key: value:
      let
        value' =
          if isBool value then
            (if value then "yes" else "no")
          else if isString value then
            ''"${value}"''
          else
            toString value;
      in
      "${key}=${value'}";
  };
  dunstConf = {
    global = {
      browser = "brave -new-tab";
      corner_radius = 8;
      dmenu = "rofi -p dunst:";
      enable_recursive_icon_lookup = true;
      ellipsize = "end";
      follow = "mouse";
      font = "${config.hm.custom.fonts.regular} 12";
      frame_color = "{{background}}";
      frame_width = 0;
      horizontal_padding = 10;
      # icon_theme will be read from $XDG_DATA_HOME/icons, these are symlinked in gtk.nix
      # TODO: use iconTheme option
      icon_theme = "Tela-Default-dark";
      icon_path = "";
      max_icon_size = 72;
      mouse_left_click = "do_action";
      mouse_middle_click = "do_action";
      mouse_right_click = "close_current";
      separator_color = "{{color7}}";
      separator_height = 1;
      show_indicators = "no";
    };

    urgency_critical = {
      background = "{{color1}}";
      foreground = "{{foreground}}";
      timeout = 0;
    };

    urgency_low = {
      background = "{{background}}${opacity}";
      foreground = "{{foreground}}";
      timeout = 10;
    };

    urgency_normal = {
      background = "{{background}}${opacity}";
      foreground = "{{foreground}}";
      timeout = 10;
    };
  };
  # NOTE: real dunst config is read from here
  dunstConfigpath = libCustom.xdgConfigPath "dunst/dunstrc";
in
mkIf (config.custom.wm != "tty") (mkMerge [
  {
    hm.programs.niri.settings.binds = {
      "Mod+n".action.spawn = [
        "dunstctl"
        "history-pop"
      ];
    };

    # keybind to show dunst history
    custom.programs = {
      hyprland.settings.bind = [
        "$mod, n, exec, dunstctl history-pop"
      ];

      mango.settings = {
        bind = [ "$mod+SHIFT, n, spawn, dunstctl history-pop" ];
      };
    };

    # dunst user service referenced from home-manager:
    # https://github.com/nix-community/home-manager/blob/master/modules/services/dunst.nix
    systemd.user.services.dunst = {
      unitConfig = {
        Description = "Dunst notification daemon";
        # ensure colorscheme is ready on boot
        AssertPathExists = [ dunstConfigpath ];
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
        X-Reload-Triggers = [ dunstConfigpath ];
      };

      serviceConfig = {
        Type = "dbus";
        BusName = "org.freedesktop.Notifications";
        ExecStart = getExe pkgs.dunst;
        ExecReload = "${getExe' pkgs.dunst "dunstctl"} reload";
      };
    };

    # create symlink in $XDG_DATA_HOME/.icons for each icon accent variant
    # allows dunst to be able to refer to icons by name
    hj.files = mapAttrs' (
      accent: _:
      let
        iconTheme = "Tela-${accent}-dark";
      in
      nameValuePair ".local/share/icons/${iconTheme}" {
        source = "${config.custom.gtk.iconTheme.package}/share/icons/${iconTheme}";
      }
    ) config.custom.gtk.accents;

    custom.programs.wallust.templates.dunstrc = {
      text = toDunstIni dunstConf;
      target = dunstConfigpath;
    };
  }
])
