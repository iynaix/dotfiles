{
  flake.nixosModules.wm =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib)
        getExe
        getExe'
        isBool
        isString
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
          browser = "helium -new-tab";
          corner_radius = 8;
          dmenu = "rofi -p dunst:";
          enable_recursive_icon_lookup = true;
          ellipsize = "end";
          follow = "mouse";
          font = "${config.custom.fonts.regular} 12";
          frame_color = "{{background}}";
          frame_width = 0;
          horizontal_padding = 10;
          # icon_theme will be read from $XDG_DATA_HOME/icons, these are symlinked in gtk.nix
          icon_theme = config.custom.gtk.iconTheme.name;
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
      dunstConfigpath = "${config.hj.xdg.config.directory}/dunst/dunstrc";
    in
    {
      # keybind to show dunst history
      custom.programs = {
        hyprland.settings.bind = [
          "$mod, n, exec, dunstctl history-pop"
        ];

        niri.settings.binds = {
          "Mod+N".action.spawn = [
            "dunstctl"
            "history-pop"
          ];
        };

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

      custom.programs.wallust.templates.dunstrc = {
        text = toDunstIni dunstConf;
        target = dunstConfigpath;
      };
    };
}
