{
  pkgs,
  lib,
  user,
  config,
  ...
}: let
  opacity = "E5";
  # used for generation of icon_path, copied home-manager's dunst source
  # https://github.com/nix-community/home-manager/blob/master/modules/services/dunst.nix
  hicolorTheme = {
    package = pkgs.hicolor-icon-theme;
    name = "hicolor";
    size = "32x32";
  };
  basePaths = [
    "/run/current-system/sw"
    config.home-manager.users.${user}.home.profileDirectory
    hicolorTheme.package
  ];
  themes = [hicolorTheme];
  categories = [
    "actions"
    "animations"
    "apps"
    "categories"
    "devices"
    "emblems"
    "emotes"
    "filesystem"
    "intl"
    "legacy"
    "mimetypes"
    "places"
    "status"
    "stock"
  ];
  mkPath = {
    basePath,
    theme,
    category,
  }: "${basePath}/share/icons/${theme.name}/${theme.size}/${category}";
  iconPath = lib.concatMapStringsSep ":" mkPath (lib.cartesianProductOfSets {
    basePath = basePaths;
    theme = themes;
    category = categories;
  });
in {
  config = {
    home-manager.users.${user} = {
      services = {
        dunst = {
          enable = true;
          configFile = "/home/${user}/.cache/wal/colors-dunstrc";
        };
      };

      xdg.configFile."wal/templates/colors-dunstrc".text = ''
        [global]
        browser="brave -new-tab"
        corner_radius=8
        dmenu="rofi -p dunst:"
        ellipsize="end"
        follow="mouse"
        font="${config.iynaix.font.regular} Regular 12"
        frame_color="{background}"
        frame_width=0
        horizontal_padding=10
        icon_path="${iconPath}"
        max_icon_size=72
        mouse_left_click="do_action"
        mouse_middle_click="do_action"
        mouse_right_click="close_current"
        separator_color="{color7}"
        separator_height=1
        show_indicators="no"

        [urgency_critical]
        background="{color1}"
        foreground="{foreground}"
        timeout=0

        [urgency_low]
        background="{background}${opacity}"
        foreground="{foreground}"
        timeout=10

        [urgency_normal]
        background="{background}${opacity}"
        foreground="{foreground}"
        timeout=10
      '';
    };
  };
}
